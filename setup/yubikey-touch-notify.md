# YubiKey touch-prompt notification (Claude Code hooks)

Goal: when a Claude Code Bash command will make the FIDO2/SK ssh key **blink for
a touch** (`git push/pull/fetch/…`, `ssh`, `scp`, `jj push`…), pop a desktop
notification with a **draining progress bar** sized to the key's touch window,
and **clear it the instant the command returns** (so it isn't a sticky toast).

These pieces are **machine-local** (they live in `~/.claude/`, not stow), so on a
new machine ask a Claude Code agent to recreate them from this file and adapt the
two machine-specific bits (notification daemon, touch-timeout). The only part
that syncs via the dotfiles is the mako style rule in
`niri/dot-config/mako/config` (`[app-name=YubiKey]`).

## Components

1. Three scripts in `~/.claude/hooks/` (full contents below), all `chmod +x`.
2. Hook wiring in `~/.claude/settings.json` (merge — don't clobber existing hooks).
3. A notification-daemon style rule (mako here; adapt if the daemon differs).

### `~/.claude/hooks/yubikey-touch-notify.sh`  — PreToolUse / Bash

```bash
#!/usr/bin/env bash
# Launch the touch toast when a Bash command will trigger a YubiKey/FIDO2 touch.
# Reads the hook JSON on stdin; ALWAYS exits 0 so it never blocks the command.
cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0
# Strip quoted args so `git commit -m "...push..."` doesn't false-trigger.
scan=$(printf '%s' "$cmd" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g")
# SSH-signing ops: git push/pull/fetch/clone/ls-remote, jj (git) push/fetch, ssh/scp/sftp.
printf '%s' "$scan" | grep -qE '(\bgit\b[^;&|]*\b(push|pull|fetch|clone|ls-remote)\b|\bjj\b[^;&|]*\b(push|fetch)\b|(^|[[:space:];&|(])(ssh|scp|sftp)( |$))' || exit 0
# Detach the countdown into its own session so it outlives this hook.
setsid -f bash "$HOME/.claude/hooks/yubikey-touch-countdown.sh" "$cmd" >/dev/null 2>&1
exit 0
```

### `~/.claude/hooks/yubikey-touch-countdown.sh`  — the draining bar

```bash
#!/usr/bin/env bash
# Draining progress-bar toast for a YubiKey touch. $1 = the command. Updates ONE
# notification's `value` 100->0 over $total seconds; stops early when the dismiss
# hook removes the id file (command finished / key tapped).
cmd=$1
total=30                                  # <-- set to the measured touch window
title="🔑 Touch your YubiKey"
idfile="${XDG_RUNTIME_DIR:-/tmp}/claude-yubikey.id"
id=$(notify-send -p -u normal -a "YubiKey" -i dialog-password \
        -h int:value:100 "$title" "$cmd" 2>/dev/null) || exit 0
printf '%s' "$id" > "$idfile"
for left in $(seq $((total - 1)) -1 0); do
    sleep 1
    [ "$(cat "$idfile" 2>/dev/null)" = "$id" ] || exit 0
    notify-send -r "$id" -u normal -a "YubiKey" -i dialog-password \
        -h int:value:$(( left * 100 / total )) "$title" "$cmd" 2>/dev/null
done
makoctl dismiss -n "$id" 2>/dev/null       # <-- daemon-specific dismiss
[ "$(cat "$idfile" 2>/dev/null)" = "$id" ] && rm -f "$idfile"
```

### `~/.claude/hooks/yubikey-touch-dismiss.sh`  — PostToolUse + PostToolUseFailure / Bash

```bash
#!/usr/bin/env bash
# Clear the toast the instant the command returns. Removing the id file also
# signals the countdown loop to stop. Fast no-op when no toast is active.
idfile="${XDG_RUNTIME_DIR:-/tmp}/claude-yubikey.id"
[ -f "$idfile" ] || exit 0
id=$(cat "$idfile" 2>/dev/null)
rm -f "$idfile"
[ -n "$id" ] && makoctl dismiss -n "$id" 2>/dev/null   # <-- daemon-specific dismiss
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

### mako style rule (already in `niri/dot-config/mako/config`)

```ini
[app-name=YubiKey]
border-color=#ffcc00            ; vivid gold
progress-color=over #3a3320     ; subtle fill
default-timeout=30000           ; fallback (= touch window); the hooks clear it sooner
[mode=do-not-disturb app-name=YubiKey]
invisible=false                 ; touch prompts pierce DnD
```

This stows to `~/.config/mako/config`, so it's already present on a machine that
stows the `niri` package — no action needed **if the daemon is mako**.

## Machine-specific things to ADAPT on a new host

1. **Notification daemon.** This host uses **mako**. If the new host runs
   something else, port the style rule and the dismiss/replace mechanics:
   - **dunst**: progress bar via the same `value` hint; replace via
     `-h string:x-dunst-stack-tag:yubikey` instead of `-r $id`; dismiss via
     `dunstctl` (e.g. close by stack tag) — `makoctl dismiss -n` won't exist.
   - **swaync / fnott / others**: check their progress-bar + close-by-id support;
     swap `makoctl dismiss -n "$id"` for the equivalent, and the `[app-name=…]`
     rule for that daemon's config syntax.
   Confirm the daemon: `pgrep -a -f 'mako|dunst|swaync|fnott'`.
2. **Touch-window length.** `total=30` (and `default-timeout`) match THIS key's
   FIDO2 user-presence timeout. Measure it on the new host — run this and **do
   not touch** the key; the `real` time ≈ the window:
   `time timeout 40 ssh -o ControlMaster=no -o ControlPath=none -T git@gitlab.com < /dev/null`
   Then set `total` in `countdown.sh` and `default-timeout` in the daemon rule.
3. **Match pattern.** Covers git/jj/ssh/scp/sftp. Add any other ssh-signing tool
   the host uses. (Local `rsync`, `ssh-add`, `ssh-keygen` are intentionally NOT
   matched.)
4. **Deps**: `jq`, `notify-send` with `-p`/`-r` (libnotify), `setsid`
   (util-linux), and the daemon's ctl. Replace `/home/USER` with the real `$HOME`.

## Verify

```bash
# script chain (bar should appear, then clear):
echo '{"tool_name":"Bash","tool_input":{"command":"git push origin main"}}' | bash ~/.claude/hooks/yubikey-touch-notify.sh
sleep 3; bash ~/.claude/hooks/yubikey-touch-dismiss.sh
# live: a real `git push` — gold bar drains while the key blinks, clears on tap.
```
