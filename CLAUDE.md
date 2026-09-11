# dotfiles

A single-user, stow-managed dotfiles repo. Sole maintainer, no reviewers.

## Git — this repo overrides the global default

`~/.claude/CLAUDE.md` says "never push to master; branch and PR always."
That stays the right default everywhere else. It does not apply here.

- **Commit and push directly to `main`.** No feature branch, no PR. A PR
  needs a reviewer, and there isn't one — the branch is pure overhead.
- **The remote is named `github`, not `origin`.** `git push origin main`
  fails; there is no `origin`. Use `git push github main`.
- Pushing here is pre-authorized, same as the global rule. Don't ask, and
  don't offer to open a PR instead.

## Stow

Files live under `<package>/dot-config/...` and are stowed into `~`, so an
edit in this repo is usually live immediately through a symlink — check
whether the target is already linked before suggesting a copy step.
