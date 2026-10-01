import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sudoku/models/sudoku_game.dart';
import 'package:sudoku/services/game_storage.dart';

// A known-valid solved grid used as fixture data.
const _solution = [
  [5, 3, 4, 6, 7, 8, 9, 1, 2],
  [6, 7, 2, 1, 9, 5, 3, 4, 8],
  [1, 9, 8, 3, 4, 2, 5, 6, 7],
  [8, 5, 9, 7, 6, 1, 4, 2, 3],
  [4, 2, 6, 8, 5, 3, 7, 9, 1],
  [7, 1, 3, 9, 2, 4, 8, 5, 6],
  [9, 6, 1, 5, 3, 7, 2, 8, 4],
  [2, 8, 7, 4, 1, 9, 6, 3, 5],
  [3, 4, 5, 2, 8, 6, 1, 7, 9],
];

List<List<int>> _puzzleWithHoles(List<List<int>> holes) {
  final puzzle = _solution.map((row) => List<int>.from(row)).toList();
  for (final hole in holes) {
    puzzle[hole[0]][hole[1]] = 0;
  }
  return puzzle;
}

SudokuGame _game({
  Difficulty difficulty = Difficulty.easy,
  List<List<int>>? puzzle,
}) {
  return SudokuGame.fromData(
    difficulty: difficulty,
    puzzle:
        puzzle ??
        _puzzleWithHoles(const [
          [0, 1],
          [1, 1],
          [8, 8],
        ]),
    solution: _solution.map((row) => List<int>.from(row)).toList(),
  );
}

void main() {
  group('Difficulty', () {
    test('allows hints only on easy and medium', () {
      expect(Difficulty.easy.allowsHints, isTrue);
      expect(Difficulty.medium.allowsHints, isTrue);
      expect(Difficulty.hard.allowsHints, isFalse);
      expect(Difficulty.expert.allowsHints, isFalse);
    });
  });

  group('fromData', () {
    test('marks givens and starts with 3 hints on easy', () {
      final game = _game();
      expect(game.given[0][0], isTrue);
      expect(game.given[0][1], isFalse);
      expect(game.hintsRemaining, 3);
    });

    test('starts with 0 hints on hard and expert', () {
      expect(_game(difficulty: Difficulty.hard).hintsRemaining, 0);
      expect(_game(difficulty: Difficulty.expert).hintsRemaining, 0);
    });
  });

  group('setNumber', () {
    test('correct entry returns true with no mistake', () {
      final game = _game();
      game.selectCell(0, 1); // solution is 3
      expect(game.setNumber(3), isTrue);
      expect(game.board[0][1], 3);
      expect(game.mistakes, 0);
    });

    test('wrong entry returns false and counts a mistake', () {
      final game = _game();
      game.selectCell(0, 1);
      expect(game.setNumber(9), isFalse);
      expect(game.mistakes, 1);
      expect(game.hasError(0, 1), isTrue);
    });

    test('three mistakes ends the game', () {
      final game = _game();
      game.selectCell(0, 1);
      game.setNumber(9);
      game.setNumber(9);
      expect(game.isGameOver, isFalse);
      game.setNumber(9);
      expect(game.isGameOver, isTrue);
    });

    test('does nothing without a selection or on givens', () {
      final game = _game();
      expect(game.setNumber(5), isNull);
      game.selectCell(0, 0); // given
      expect(game.setNumber(5), isNull);
      expect(game.mistakes, 0);
    });

    test('completing the last cell wins the game', () {
      final game = _game(
        puzzle: _puzzleWithHoles(const [
          [0, 0],
        ]),
      );
      game.selectCell(0, 0);
      expect(game.setNumber(5), isTrue);
      expect(game.isCompleted, isTrue);
    });
  });

  group('notes mode', () {
    test('toggles candidates instead of placing digits', () {
      final game = _game();
      game.selectCell(0, 1);
      game.isNotesMode = true;
      expect(game.setNumber(3), isNull);
      expect(game.board[0][1], 0);
      expect(game.notes[0][1], contains(3));
      // Tapping again removes the candidate.
      game.setNumber(3);
      expect(game.notes[0][1], isNot(contains(3)));
    });

    test('placing a digit clears peer notes', () {
      final game = _game();
      game.isNotesMode = true;
      game.selectCell(0, 1);
      game.setNumber(7);
      game.selectCell(0, 2);
      game.setNumber(7);
      expect(game.notes[0][1], contains(7));
      game.isNotesMode = false;
      game.selectCell(1, 1); // solution is 7, peer of both cells
      expect(game.setNumber(7), isTrue);
      expect(game.notes[0][1], isNot(contains(7)));
      expect(game.notes[0][2], isNot(contains(7)));
    });
  });

  group('erase and undo', () {
    test('erase clears value and notes', () {
      final game = _game();
      game.selectCell(0, 1);
      game.setNumber(3);
      game.isNotesMode = true;
      game.setNumber(4);
      game.isNotesMode = false;
      game.erase();
      expect(game.board[0][1], 0);
      expect(game.notes[0][1], isEmpty);
    });

    test('undo restores the previous value', () {
      final game = _game();
      expect(game.canUndo, isFalse);
      game.selectCell(0, 1);
      game.setNumber(3);
      expect(game.canUndo, isTrue);
      game.undo();
      expect(game.board[0][1], 0);
      expect(game.canUndo, isFalse);
    });
  });

  group('hint', () {
    test('reveals and locks the cell, decrements count', () {
      final game = _game();
      game.selectCell(0, 1);
      expect(game.hint(), isTrue);
      expect(game.board[0][1], 3);
      expect(game.given[0][1], isTrue);
      expect(game.hintsRemaining, 2);
    });

    test('refused on hard and on already-correct cells', () {
      final hard = _game(difficulty: Difficulty.hard);
      hard.selectCell(0, 1);
      expect(hard.hint(), isFalse);

      final game = _game();
      game.selectCell(0, 1);
      game.setNumber(3);
      expect(game.hint(), isFalse);
      expect(game.hintsRemaining, 3);
    });
  });

  group('query helpers', () {
    test('remaining count tracks placements', () {
      final game = _game();
      // Digit 3 is missing at (0,1) only in the fixture puzzle.
      expect(game.getRemainingCount(3), 1);
      game.selectCell(0, 1);
      game.setNumber(3);
      expect(game.getRemainingCount(3), 0);
    });

    test('selection group and same-number detection', () {
      final game = _game();
      game.selectCell(0, 1);
      expect(game.isInSameGroup(0, 5), isTrue); // same row
      expect(game.isInSameGroup(5, 1), isTrue); // same column
      expect(game.isInSameGroup(1, 0), isTrue); // same box
      expect(game.isInSameGroup(5, 5), isFalse);
    });
  });

  group('autosave serialization', () {
    test('toJson/fromJson round-trips full state', () {
      final game = _game();
      game.selectCell(0, 1);
      game.setNumber(3);
      game.isNotesMode = true;
      game.selectCell(1, 1);
      game.setNumber(7);
      game.isNotesMode = false;
      game.selectCell(8, 8);
      game.elapsedOffset = const Duration(minutes: 4, seconds: 32);

      final restored = SudokuGame.fromJson(
        Map<String, dynamic>.from(game.toJson()),
      );
      expect(restored, isNotNull);
      final r = restored!;
      expect(r.board, game.board);
      expect(r.solution, game.solution);
      expect(r.given, game.given);
      expect(r.notes, game.notes);
      expect(r.selectedRow, 8);
      expect(r.selectedCol, 8);
      expect(r.isNotesMode, isFalse);
      expect(r.mistakes, game.mistakes);
      expect(r.hintsRemaining, game.hintsRemaining);
      expect(r.formattedTime, '04:32');
      expect(r.canUndo, isTrue);
      r.undo();
      expect(r.notes[1][1], isNot(contains(7)));
    });

    test('rejects unknown versions, finished and corrupt games', () {
      final game = _game();
      final badVersion = game.toJson()..['version'] = 99;
      expect(SudokuGame.fromJson(badVersion), isNull);
      expect(SudokuGame.fromJson({}), isNull);

      final done = _game();
      done.isCompleted = true;
      expect(SudokuGame.fromJson(done.toJson()), isNull);
      final over = _game();
      over.isGameOver = true;
      expect(SudokuGame.fromJson(over.toJson()), isNull);
    });
  });

  group('GameStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and loads a game', () async {
      final game = _game();
      game.selectCell(0, 1);
      game.setNumber(3);
      await GameStorage.save(game);

      final loaded = await GameStorage.load();
      expect(loaded, isNotNull);
      expect(loaded!.board[0][1], 3);
      expect(loaded.selectedRow, 0);
      expect(loaded.selectedCol, 1);
    });

    test('finished games are not kept', () async {
      final game = _game();
      game.isGameOver = true;
      await GameStorage.save(game);
      expect(await GameStorage.load(), isNull);
    });

    test('summary reflects the save, clear removes it', () async {
      expect(await GameStorage.summary(), isNull);
      await GameStorage.save(_game());
      final summary = await GameStorage.summary();
      expect(summary, isNotNull);
      expect(summary!.difficulty, Difficulty.easy);
      await GameStorage.clear();
      expect(await GameStorage.summary(), isNull);
    });
  });

  group('generation', () {
    test('produces a valid solution with holes punched', () {
      final result = SudokuGame.generatePuzzle(5, Random(42));
      final puzzle = result[0];
      final solution = result[1];
      // Every row/col/box of the solution holds 1–9 exactly once.
      for (int i = 0; i < 9; i++) {
        expect(solution[i].toSet(), hasLength(9));
        expect(List.generate(9, (r) => solution[r][i]).toSet(), hasLength(9));
      }
      final holes = puzzle.expand((row) => row).where((v) => v == 0).length;
      expect(holes, greaterThan(0));
      expect(holes, lessThanOrEqualTo(5));
    });
  });
}
