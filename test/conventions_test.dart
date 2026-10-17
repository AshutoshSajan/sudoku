import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contract tests pinning the convention & trunk-safety stack
/// (CONVENTIONS.md): hooks, CI guards, docs wiring. These fail loudly if
/// a refactor quietly drops a guard.
String _root() {
  var dir = Directory.current.absolute;
  while (!File('${dir.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) fail('could not locate the repo root');
    dir = parent;
  }
  return dir.path;
}

String _read(String relativePath) {
  final file = File('${_root()}${Platform.pathSeparator}$relativePath');
  if (!file.existsSync()) fail('missing required file: $relativePath');
  return file.readAsStringSync();
}

/// Runs .githooks/pre-push directly with a fake git pre-push payload:
/// ARGV = remote name + URL; STDIN = `<local-ref> <sha> <remote-ref> <sha>`
/// lines. [gate] replaces the default verify gate so tests stay cheap
/// (that env override is a documented, test-only hook bypass).
Future<int> _runPrePush({
  List<String> args = const [],
  List<String> stdinLines = const [],
  String? gate,
}) async {
  final hook = '${_root()}${Platform.pathSeparator}.githooks'
      '${Platform.pathSeparator}pre-push';
  final env = gate == null
      ? null
      : {...Platform.environment, 'SUDOKU_HOOK_GATE': gate};
  final proc = await Process.start(hook, args, environment: env);
  proc.stdin.write('${stdinLines.join('\n')}\n');
  await proc.stdin.flush();
  await proc.stdin.close();
  final out = await utf8.decodeStream(proc.stdout);
  final err = await utf8.decodeStream(proc.stderr);
  final code = await proc.exitCode;
  // Surface the hook's own output so refusals are readable in test logs.
  if (out.isNotEmpty) stdout.write(out);
  if (err.isNotEmpty) stdout.write(err);
  return code;
}

String _shaOf(String source) => RegExp('([0-9a-f]{64})').firstMatch(source)?.group(1) ?? '';

String _versionOf(String source) =>
    RegExp(r'OSV_SCANNER_VERSION[^0-9]*(\d+\.\d+\.\d+)').firstMatch(source)?.group(1) ?? '';

void main() {
  group('hooks', () {
    test('dev push via stdin is refused, naming the rule', () async {
      final code = await _runPrePush(
        args: ['origin', 'https://github.com/AshutoshSajan/sudoku.git'],
        stdinLines: ['refs/heads/dev ${'a' * 40} refs/heads/dev ${'b' * 40}'],
      );
      expect(code, 1);
    });

    test('main push (deletion form) via stdin is refused', () async {
      final code = await _runPrePush(
        args: ['origin', 'https://github.com/AshutoshSajan/sudoku.git'],
        stdinLines: [' refs/heads/main ${'c' * 40} refs/heads/main ${'0' * 40}'],
      );
      expect(code, 1);
    });

    test('argv trunk refspec (":refs/heads/dev") is refused', () async {
      final code = await _runPrePush(args: [':refs/heads/dev']);
      expect(code, 1);
    });

    test('boundary: refs/heads/mainfoo is not a trunk', () async {
      final code = await _runPrePush(
        args: ['origin', 'https://example.com/x.git'],
        stdinLines: [
          'refs/heads/mainfoo ${'d' * 40} refs/heads/mainfoo ${'e' * 40}',
        ],
        gate: 'true',
      );
      expect(code, 0);
    });

    test('task-branch push falls through to the gate', () async {
      final code = await _runPrePush(
        args: ['origin', 'https://github.com/AshutoshSajan/sudoku.git'],
        stdinLines: [
          'refs/heads/feat/x ${'a' * 40} refs/heads/feat/x ${'b' * 40}',
        ],
        gate: 'echo gate-ran',
      );
      expect(code, 0);
    });

    test('pre-push hygiene: GIT_* unset line, default gate is tool/verify.sh', () {
      final hook = _read('.githooks/pre-push');
      expect(hook, contains('unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE'));
      expect(hook, contains('GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_PREFIX'));
      expect(hook, contains('tool/verify.sh'));
      expect(hook, contains('SUDOKU_HOOK_GATE'));
    });

    test('hooks and tool scripts are executable', () {
      for (final path in [
        '.githooks/pre-push',
        '.githooks/post-merge',
        '.githooks/commit-msg',
        'tool/verify.sh',
        'tool/deps.sh',
      ]) {
        final stat = File('${_root()}${Platform.pathSeparator}$path').statSync();
        expect(stat.mode & 0x49, isNot(0), reason: '$path must be executable');
      }
    });

    test('post-merge prunes remote refs + self-heals hooksPath', () {
      final postMerge = _read('.githooks/post-merge');
      expect(postMerge, contains('git fetch --prune origin'));
      expect(postMerge, contains('core.hooksPath .githooks'));
      expect(postMerge, contains('|| true'), reason: 'offline merges stay offline');
    });
  });

  group('ci guards', () {
    test('trunk guards exist, trigger on push to the trunk, read the payload', () {
      final guardDev = _read('.github/workflows/guard-dev.yml');
      expect(guardDev, contains('branches: [dev]'));
      expect(guardDev, contains('permissions: {}'));
      expect(guardDev, contains('head_commit.parents | length'));
      expect(guardDev, contains('.forced'));
      expect(guardDev, isNot(contains('actions/checkout')));

      final guardMain = _read('.github/workflows/guard-main.yml');
      expect(guardMain, contains('branches: [main]'));
      expect(guardMain, contains('head_commit.parents | length'));
      expect(guardMain, isNot(contains('actions/checkout')));
    });

    test('pruner: closed-PR trigger, allowlist, trunk protection, ancestry proof', () {
      final prune = _read('.github/workflows/prune-branch.yml');
      expect(prune, contains('types: [closed]'));
      expect(prune, contains('branches: [dev, main]'));
      expect(prune, contains('merged == true'));
      expect(prune, contains('merge-base --is-ancestor'));
      expect(prune, contains('--delete'));
      expect(prune, contains('feat/*|fix/*|chore/*'));
      expect(prune, contains('main|dev'));
    });

    test('one writer per concern: no inline prune in other workflows', () {
      final workflows = Directory('${_root()}${Platform.pathSeparator}.github'
              '${Platform.pathSeparator}workflows')
          .listSync()
          .whereType<File>()
          .toList();
      for (final file in workflows) {
        if (file.path.endsWith('prune-branch.yml')) continue;
        expect(
          file.readAsStringSync(),
          isNot(contains('closed]')),
          reason: '${file.path} must not prune inline — prune-branch.yml owns it',
        );
      }
    });

    test('deps-audit: pinned scanner, sha256 gate, cron, PR-into-main gate', () {
      final audit = _read('.github/workflows/deps-audit.yml');
      expect(audit, contains('osv-scanner scan --lockfile=pubspec.lock'));
      expect(audit, contains('sha256sum -c -'));
      expect(audit, contains('cron:'));
      expect(audit, contains('pull_request:'));
      expect(audit, contains('branches: [main]'));
      expect(_shaOf(audit), hasLength(64));
    });

    test('.github/dependabot.yml ships pub + github-actions, targets dev', () {
      final dependabot = _read('.github/dependabot.yml');
      expect(dependabot, contains('pub'));
      expect(dependabot, contains('github-actions'));
      expect(dependabot, contains('interval: weekly'));
      expect(dependabot, contains('target-branch: "dev"'));
    });

    test('osv-scanner pin consistent between CI and tool/deps.sh', () {
      final audit = _read('.github/workflows/deps-audit.yml');
      final local = _read('tool/deps.sh');
      expect(_shaOf(audit), isNotEmpty);
      expect(_shaOf(audit), _shaOf(local), reason: 'scanner sha256 must match CI');
      expect(_versionOf(audit), isNotEmpty);
      expect(_versionOf(audit), _versionOf(local), reason: 'scanner version must match CI');
    });
  });

  group('docs', () {
    test('AGENTS.md carries the inline hard rules', () {
      final agents = _read('AGENTS.md');
      for (final needle in [
        'gh pr create --base dev',
        'core.hooksPath .githooks',
        'bash tool/verify.sh',
        'TRUNCATE',
        'never hand-edited',
        '--offline',
        'worktree',
        'flutter pub get',
      ]) {
        expect(agents, contains(needle), reason: 'AGENTS.md missing: $needle');
      }
    });

    test('CLAUDE.md imports AGENTS.md and adds no duplicate rule text', () {
      final content = _read('CLAUDE.md');
      final nonEmpty =
          content.trim().split('\n').where((line) => line.trim().isNotEmpty);
      expect(nonEmpty.length, 2, reason: 'CLAUDE.md must stay two lines');
      expect(content, contains('@AGENTS.md'));
    });

    test('README links conventions/roadmap and drops retired tier names', () {
      final readme = _read('README.md');
      expect(readme, contains('CONVENTIONS.md'));
      expect(readme, contains('ROADMAP.md'));
      for (final retired in ['feature/', 'bugfix/', 'hotfix/']) {
        expect(readme, isNot(contains(retired)),
            reason: 'retired prefix "$retired" must not reappear in README');
      }
    });

    test('CONVENTIONS.md is canonical and links the roadmap', () {
      final content = _read('CONVENTIONS.md');
      expect(content, contains('ROADMAP.md'));
      expect(content, contains('merge commit'));
      expect(content, contains('Never'));
    });
  });
}
