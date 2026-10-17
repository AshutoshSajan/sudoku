# Contributing to Sudoku

All process documentation — branch model, trunk-safety rules, commits,
changelog policy, release contract, extension publishing, CI guards — has
moved to **[CONVENTIONS.md](CONVENTIONS.md)** (canonical) and
**[ROADMAP.md](ROADMAP.md)** (in-flight work). Agents should start at
[AGENTS.md](AGENTS.md).

## The short version

```sh
git config core.hooksPath .githooks    # one-time per clone
git checkout -b feat/awesome-thing origin/dev
# ... work, commit (Conventional Commits) ...
bash tool/verify.sh                    # flutter analyze + flutter test
git push -u origin feat/awesome-thing
gh pr create --base dev                # into dev; merge = merge commit
```

Releases: a PR from `dev` into `main`, then tag the newest merge commit
**without** `[skip ci]` in its message as `vX.Y.Z` — details in
[CONVENTIONS.md §6](CONVENTIONS.md).
