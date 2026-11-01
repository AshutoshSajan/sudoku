# Roadmap

Status, todos, and working notes. Product facts live in the
[README](README.md); the process rules live in [CONVENTIONS.md](CONVENTIONS.md).

## Shipped

- [x] Autosave with resume, keyboard support, in-game help, responsive layouts
- [x] One-tag multi-format binary releases (apk/aab/deb/rpm/AppImage/snap/exe/web)
- [x] Snap packaging, F-Droid metadata + submission
- [x] Convention & trunk-safety stack: trunk guards (`guard-dev.yml`,
  `guard-main.yml`), auto-pruner (`prune-branch.yml`), dependency audit
  (`deps-audit.yml`, Dependabot), `pre-push` trunk armor + verify gate

## In review

- [ ] **F-Droid inclusion** — metadata MR
  [!51869](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/51869)
  (`New app: Sudoku`) is under fdroiddata maintainer review. Recipe points at
  `main` @ `7a1cb10`; changelog links use `blob/HEAD`. If reviewers comment,
  re-verify `fdroid lint com.ashutoshsajan.sudoku` against the current
  signed tag before pushing fixes to the fork recipe.

## Planned

- [ ] Chrome Web Store listing (needs `CHROME_*` store secrets; job skeleton
  already in `ci.yaml` as a commented `publish-chrome` job)
- [ ] Signed Firefox add-on (`publish-firefox` job is live; needs
  `AMO_API_KEY`/`AMO_API_SECRET`)
- [ ] Snap Store listing (snapcraft already packaged)
- [ ] Signed Windows installer (no more SmartScreen warning)

## Working notes (retire when done)

- Release contract of record: tag is version truth; tag the newest `main`
  merge commit *without* `[skip ci]` (the changelog bot's commit suppresses
  tag-push runs); re-rolls require deleting the published GitHub Release in
  the browser first. All deploys (app, extension, hosted web) fire on tag
  pushes only — hosted web deploys via `release.yaml` → `deploy-web` need
  the `NETLIFY_DEPLOY_HOOK_URL` repo secret (create a Production-scoped
  build hook in the Netlify UI, then add the secret), so the web site stays
  frozen until that is done; `netlify.toml`'s `ignore` command already
  skips all git-triggered builds, so merges to main are inert meanwhile.
- Changelog CI-only: pulls on `dev` regenerated `CHANGELOG.md` because
  `.githooks/post-merge` rendered git-cliff locally after every merge
  (the Oct-9 bot commits visible in dev history are pre-split residue —
  the bot itself has always been main-only). Fix: the hook renders
  nothing anymore; changelog truth = the bot writes the committed file
  on `main` pushes (file stays committed — F-Droid metadata links it),
  and release.yaml ships `CHANGELOG-vX.Y.Z.md` as a Release asset
  (git-cliff-action `--latest`).
- Web-deploy hardening (from the PR review): `tool/netlify-build.sh` should
  inject `--build-name` from the newest `v*` tag (`git describe --tags
  --abbrev=0 --match 'v*'`) to match `release.yaml`'s builds, and
  `deploy-web` could grow a post-deploy live check once a site URL is
  available as a repo variable.
- GitHub Pages mirror: flip Settings → Pages → Build source to
  "GitHub Actions" once (until then `deploy-gh-pages` fails loudly); after
  the first successful tag deploy, add the mirror link
  (`https://ashutoshsajan.github.io/sudoku/`) beside the Netlify links in
  `README.md`.
- When store listings land, replace the "Store status" note in
  `README.md#-installation` — the only place store status appears.
- `conventions` stack review date: revisit guards after the first release
  PR that merges `dev` → `main` under the new model, so the flow is
  exercised end to end.
