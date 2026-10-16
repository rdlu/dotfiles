# YubiKey touch-prompt notification (Claude Code hooks)

Goal: when a Claude Code Bash command makes the FIDO2/SK ssh key **blink for a
touch** (`git push/pull/fetch/…`, `ssh`, `scp`, `jj push`…), pop a desktop
notification with the command and a **draining progress bar** sized to the key's
touch window, and **clear it the instant the key stops waiting**.

The toast is driven by the key, not by guessing from the command line: the
stowed `yubikey-touch-notifier` service (consumes `yubikey-touch-detector`'s
socket) is the only thing that shows it, and only after a request has been
pending for 0.6s, so brief probes never surface. The Claude hooks just *arm* it
with the command text; ssh over a live ControlMaster or an https remote matches
the hook but never toasts. Touches from anything else (terminal ssh, WebAuthn,
pam-u2f, GPG) get a low-urgency toast naming the process holding the key.

The two hooks are **machine-local** (they live in `~/.claude/`, not stow), so on
a new machine ask a Claude Code agent to recreate them from this file.

## Components

1. `yubikey-touch-detector` (package) + `yubikey-touch-notifier.service`
   (stowed, `systemctl --user enable --now`). `TOUCH_WINDOW` and `DEBOUNCE` are
   constants at the top of the notifier script.
2. Two scripts in `~/.claude/hooks/` (below), `chmod +x`.
3. Hook wiring in `~/.claude/settings.json` (merge — don't clobber existing hooks).

### `~/.claude/hooks/yubikey-touch-notify.sh`  — PreToolUse / Bash

```bash
#!/usr/bin/env bash
# Arm the notifier's touch toast for a command that may need the SK key.
# Reads the hook JSON on stdin; ALWAYS exits 0 so it never blocks the command.
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
# Strip quoted args so `git commit -m "...push..."` doesn't arm it.
scan=$(printf '%s' "$cmd" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")
printf '%s' "$scan" | grep -qE '(\bgit\b[^;&|]*\b(push|pull|fetch|clone|ls-remote)\b|\bjj\b[^;&|]*\b(push|fetch)\b|(^|[[:space:];&|(])(ssh|scp|sftp)( |$))' || exit 0
printf '%s' "$cmd" > "${XDG_RUNTIME_DIR:-/tmp}/claude-yubikey.cmd"
exit 0
```

### `~/.claude/hooks/yubikey-touch-dismiss.sh`  — PostToolUse + PostToolUseFailure / Bash

```bash
#!/usr/bin/env bash
# Disarm when the command returns; the notifier closes the toast itself on *_0.
rm -f "${XDG_RUNTIME_DIR:-/tmp}/claude-yubikey.cmd"
exit 0
```

### `~/.claude/settings.json` (merge into existing `hooks`)

Add the notify hook to **PreToolUse/Bash**, and the dismiss hook to **both
PostToolUse/Bash and PostToolUseFailure/Bash**, alongside whatever is already
there (e.g. the `atuin hook claude-code` entries). Use `async: true`.

```jsonc
// in hooks.PreToolUse[] matcher "Bash" -> hooks[]:
{ "type": "command", "command": "bash '/home/USER/.claude/hooks/yubikey-touch-notify.sh'", "async": true, "timeout": 5 }
// in hooks.PostToolUse[] AND hooks.PostToolUseFailure[] matcher "Bash" -> hooks[]:
{ "type": "command", "command": "bash '/home/USER/.claude/hooks/yubikey-touch-dismiss.sh'", "async": true, "timeout": 5 }
```

Validate after editing:
`jq -e '.hooks.PreToolUse' ~/.claude/settings.json` (a malformed file silently
disables ALL settings). If hooks don't fire this session, open `/hooks` once or
restart (the settings watcher only tracks dirs that had a settings file at start).

## Machine-specific things to ADAPT on a new host

1. **Notification daemon.** Dismissal is daemon-agnostic (`CloseNotification`
   over D-Bus); replace-in-place (`notify-send -r`) and the progress `value`
   hint depend on the daemon (Noctalia supports both). Confirm the daemon:
   `busctl --user status org.freedesktop.Notifications | grep Comm=`.
2. **Touch-window length.** `TOUCH_WINDOW = 30` in the notifier matches THIS
   key's FIDO2 user-presence timeout. Measure it — run this and **do not touch**
   the key; the `real` time ≈ the window:
   `time timeout 40 ssh -o ControlMaster=no -o ControlPath=none -T git@gitlab.com < /dev/null`
3. **Deps**: `jq`, `notify-send` with `-p`/`-r` (libnotify), `gdbus`. Replace
   `/home/USER` with the real `$HOME`.

## Verify

A real `git push` from Claude Code: the bar appears ~0.6s after the key starts
blinking and clears on tap. `ssh <host>` with a live ControlMaster: no toast.
