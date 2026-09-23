# dotfiles

A single-user, stow-managed dotfiles repo. Sole maintainer, no reviewers.

## Git — this repo overrides the global default

`~/.claude/CLAUDE.md` says "never push to master; branch and PR always."
That stays the right default everywhere else. It does not apply here.

- **Commit and push directly to `main`.** No feature branch, no PR. A PR
  needs a reviewer, and there isn't one — the branch is pure overhead.
- **Three remotes: `origin`, `github`, `gitlab`.** `origin` fetches from
  gitlab and has *two* push URLs, so `git push origin main` publishes to
  both — that's the normal push. `github` and `gitlab` address one each,
  for when they've diverged. Only github runs the docs CI.
- **Pushing needs a tap on the hardware SSH key** (ED25519-SK). Run the push
  (and any other git-over-ssh op) yourself — the key blinks and the user gets
  notified and taps it. Allow up to 3 attempts, then stop and report.
  `agent refused operation` usually just means the touch timed out — retry.
  If it persists, check `lsusb` for the Yubico device: absent means the key
  isn't being read. `origin` can land on gitlab and fail on github, so retry
  just the failed remote.
- Pushing here is pre-authorized, same as the global rule. Don't ask, and
  don't offer to open a PR instead.

## Stow

Files live under `<package>/dot-config/...` and are stowed into `~`, so an
edit in this repo is usually live immediately through a symlink — check
whether the target is already linked before suggesting a copy step.
