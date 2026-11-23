# YubiKey touch-prompt notification

Goal: when anything makes the FIDO2/SK key **blink for a touch** (`git
push/pull/fetch`, `ssh`, `scp`, WebAuthn, pam-u2f, GPG), show a desktop
notification. The notification **clears the instant the key stops waiting**.

The key drives the toast, not a guess from the command line. Two user services
do the work for every process in the session, Claude Code included. No Claude
Code hooks are needed (they were removed on purpose).

## Components

1. `yubikey-touch-detector` (package) with its user service. It watches the key
   and writes 5-byte events to `$XDG_RUNTIME_DIR/yubikey-touch-detector.socket`:
   `U2F_1`/`U2F_0`, `GPG_1`/`GPG_0`, `MAC_1`/`MAC_0`.
2. `yubikey-touch-notifier` (stowed: `scripts/dot-local/bin/`) and
   `yubikey-touch-notifier.service` (stowed: `niri/dot-config/systemd/user/`).
   It reads the detector socket:
   - A `*_1` event must stay pending for `DEBOUNCE` (0.6 s) before a toast
     shows, so short probes (libfido2 enumeration, browsers that poll the key)
     never show one.
   - The toast is low urgency and names the process that holds the YubiKey's
     FIDO hidraw, as a hint.
   - A `*_0` event closes it through the freedesktop `CloseNotification` D-Bus
     call.

Enable both:

```
systemctl --user enable --now yubikey-touch-detector.service yubikey-touch-notifier.service
```

The notifier still has a second mode: a normal-urgency toast with a draining
progress bar when `$XDG_RUNTIME_DIR/claude-yubikey.cmd` exists. Claude Code hooks
used to write that file. Nothing writes it now, so that mode does not run.

## The SSH key and the agent

- `~/.ssh/id_ed25519_sk` has a passphrase. `ssh-unlock` (stowed:
  `niri/dot-local/bin/`, also in the power menu, Mod+Escape) loads it into
  `ssh-agent.service` (socket `$XDG_RUNTIME_DIR/ssh-agent.socket`).
- After the unlock, **each signature still needs a touch**. The key waits about
  `TOUCH_WINDOW` (30 s) for it.
- LED **steady** = the key is idle. LED **flashing** = it waits for a touch.
  A short touch on a steady LED types an OTP string into the focused window.
- A signature that gets no touch in time fails. Through the agent, ssh then
  prints `sign_and_send_pubkey: signing failed … agent refused operation`
  and `Permission denied (publickey)`.

## Troubleshooting

- `ssh-unlock status`: `loaded`, `locked` or `noagent`.
- Test one signature through the agent, and watch the LED:
  `echo hi | ssh-keygen -Y sign -f ~/.ssh/id_ed25519_sk.pub -n test`
- Skip the agent (ssh uses the key file and asks for the passphrase and touch):
  `SSH_AUTH_SOCK= git push`
- The key sits on a hub port that is not reliable. After a failure, look for a
  drop: `journalctl -k | grep -i 'usb 3-1'`.
- No toast at all: `systemctl --user status yubikey-touch-detector yubikey-touch-notifier`.

## Machine-specific things to ADAPT on a new host

1. **Notification daemon.** The close step works with any daemon
   (`CloseNotification` over D-Bus). Replace-in-place (`notify-send -r`) and the
   progress `value` hint depend on the daemon (Noctalia supports both). Find the
   daemon: `busctl --user status org.freedesktop.Notifications | grep Comm=`.
2. **Touch-window length.** `TOUCH_WINDOW = 30` in the notifier matches THIS
   key's FIDO2 user-presence timeout. To measure it, run this and **do not
   touch** the key. The `real` time is about the window:
   `time timeout 40 ssh -o ControlMaster=no -o ControlPath=none -T git@gitlab.com < /dev/null`
3. **Deps**: `python3`, `notify-send` with `-p`/`-r` (libnotify), `gdbus`.

## Verify

Run `ssh -T git@github.com` in a terminal. The toast shows about 0.6 s after
the key starts to flash, and it closes when you touch the key. `ssh <host>` with
a live ControlMaster needs no signature, so it shows no toast.
