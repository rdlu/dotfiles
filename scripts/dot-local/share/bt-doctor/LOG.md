# bt-doctor — project log

Handoff notes so the work can continue on another machine (daisy).
Started 2026-10-21 on **xps** (CachyOS, BlueZ, Intel BT chip via
`btusb` + `btintel`).

## 1. The incident that started it

Bluetooth on xps got stuck on *"operation already in progress"*
(`org.bluez.Error.InProgress`). Devices involved:

| Device | Kind | Notes |
|---|---|---|
| Eyelash Sofle | ZMK split keyboard (BLE) | had to be re-paired |
| ProtoArc T1 Plus | BLE keyboard + touchpad | touchpad stopped moving the pointer |
| MX Master 3 | BLE mouse | paired, untouched |
| WH-XB900N | Sony headphones (classic BT audio) | paired, untouched |

### What we tried, in order, and what each did

1. **Read the journal**
   (`journalctl -b -u bluetooth`). It was flooded with BLE HID errors from
   `hog-lib.c` (`Read Report Reference descriptor failed`,
   `HID Information read failed`, `read_pnpid_cb() Error reading PNP_ID`),
   then `Pair device failed: Timeout (0x08)`.
2. **`bluetoothctl power off` / `power on`** failed:
   `Failed to set power off: org.bluez.Error.Failed`, and journal
   `Failed to set mode: Disconnected (0x0e)`. The controller itself was wedged.
3. **`rfkill block bluetooth; sleep 2; rfkill unblock bluetooth`** (no root
   needed). Power state recovered and the ProtoArc reconnected, **but
   discovery stayed wedged**: `bluetoothctl scan on` gave
   `Failed to start discovery: org.bluez.Error.InProgress` while
   `bluetoothctl show` said `Discovering: no`. The user's GUI (`bluetui`)
   showed this as "error when I try to scan". The error came from the stack,
   not from bluetui.
4. **`sudo` failed** (password, non-interactive). **`pkexec` worked**: one
   polkit prompt for
   `pkexec sh -c 'systemctl stop bluetooth; modprobe -r btusb btintel; sleep 1; modprobe btusb; systemctl start bluetooth'`.
   **This is what fixed it.** Scanning worked straight away.
5. **First re-pair of the Sofle** connected but did **not** bond
   (`Paired: no`). Journal: `No agent available for request type 2` /
   `device_confirm_passkey: Operation not permitted`. **Cause:** bluetui's
   pairing agent died with the daemon restart, and non-interactive
   `bluetoothctl pair` registers no agent.
6. **Re-pair with a scripted agent** worked. Pipe commands into an
   interactive `bluetoothctl`:
   ```fish
   { echo "agent NoInputNoOutput"; sleep 1; echo "default-agent"; sleep 1
     echo "scan on"; sleep 5; echo "pair $M"; sleep 4; echo "yes"; sleep 6
     echo "yes"; sleep 4; echo "scan off"; echo "connect $M"; sleep 6
     echo "quit"; } | bluetoothctl
   bluetoothctl trust $M
   ```
   The `Accept pairing (yes/no)` prompt appeared and `yes` bonded it. The Sofle
   ended up paired, bonded, trusted and connected (battery 52%).
7. **The ProtoArc touchpad stopped moving the pointer** after all this,
   even though the keys worked. It recovered by itself after a short while.
   Our theory (not verified): the BLE HID report setup (the `hog-lib` errors
   above) hadn't finished after the restart, and the ProtoArc was probably
   the source of those errors all along. If it happens again:
   `bluetoothctl disconnect <mac>; sleep 2; bluetoothctl connect <mac>`, and
   re-pair if it keeps happening. (An early guess that the desktop disables the
   touchpad when the Sofle's "Mouse" HID device appears was wrong. It's the
   ProtoArc's own touchpad.)

### Lessons

- Escalation ladder: `bluetoothctl` power cycle → `rfkill` cycle → daemon
  restart + driver reload (root). Only the last clears a wedged discovery.
- After any daemon restart, **restart bluetui** (or any GUI agent), or
  pairing silently fails with "No agent available".
- `bluetoothctl --timeout N connect` always waits the full N seconds. Use
  `timeout 30 bluetoothctl connect` instead.
- Root-only BlueZ store `/var/lib/bluetooth/<adapter>/` keeps bonds
  (`<MAC>/info`) **and** a name cache (`cache/<MAC>`) for devices seen or
  paired before, even after `bluetoothctl remove`. Read it with
  `sudo grep -H '^Name=' /var/lib/bluetooth/*/cache/* /var/lib/bluetooth/*/*/info`.
- Privilege pattern in these dotfiles: root → direct; graphical session →
  `pkexec` (one `sh -c` = one prompt); plain tty → `sudo` (see
  `localsend-here`).

## 2. What was built: `bt-doctor`

`scripts/dot-local/bin/bt-doctor` (fish, ~1000 lines, `pkg-tui`-style fzf
TUI). Commit `995f960`. Also added:
- an item "Bluetooth doctor" (Network group) in
  `niri/dot-config/rodii-power-menu/menu.kdl`
- `bluez-utils` to `setup/packages.yaml` (niri-wm category, next to `bluetui`)

On a new machine, stow it:
`stow -v --dotfiles -d ~/.dotfiles -t ~/ scripts`.

### Command surface

```
bt-doctor                      TUI: adapter + paired devices, live preview
bt-doctor diagnose             read-only report + suggested fixes
bt-doctor fix                  power → rfkill → daemon+driver, verify each, stop at first that works
bt-doctor reconnect [dev]      disconnect, wait, connect
bt-doctor pair [dev]           remove, pair with scripted agent, trust, connect
bt-doctor remove [dev]
bt-doctor reset power|rfkill|daemon|audio
bt-doctor list [--paired|--connected|--all|--history] [-q]   MAC<TAB>name<TAB>state
bt-doctor pick [filter]        fzf over list, prints MAC(s)
```

`[dev]` is a MAC or a case-insensitive name substring. It falls back to
`--history` (one privilege prompt) when nothing known matches. With no `[dev]`,
MACs are read from stdin, so commands chain:

```fish
bt-doctor pair (bt-doctor pick --history)
bt-doctor list --history | fzf | cut -f1 | bt-doctor pair
bt-doctor list --connected -q | xargs -n1 bt-doctor reconnect
```

TUI keys: enter = action menu · ctrl-r reconnect · ctrl-p re-pair ·
ctrl-x remove · ctrl-d diagnose · ctrl-f fix · ctrl-n scan & pair new.

### Design notes

- **`fix` verification**: after each level it checks that the adapter is
  powered **and** that `bluetoothctl --timeout 3 scan on` prints "Discovery
  started" without InProgress.
- **Daemon reset** removes every vendor module lsmod shows `btusb` using
  (btintel/btrtl/btmtk/btbcm) in one privileged `sh` script. It has no
  `set -e` and always ends with `systemctl start bluetooth`.
- **Pair flow**: `$SELF __feed MAC | bluetoothctl`. The feeder is a
  separate process because fish buffers a `begin…end` block's output in a
  pipeline. It polls `bluetoothctl info` for Paired/Connected instead of
  fixed sleeps, and sends `yes` every 2 s. The pairing-mode reminder (ZMK:
  `BT_CLR` on the profile) and confirmations read `/dev/tty`, so piped use
  works.
- **`diagnose`** matches journal signatures (InProgress, Failed to set mode,
  No agent available, hog-lib read failures, Pair device failed: Timeout).
  It marks hits from an earlier bluetoothd process (by MainPID) as "before
  the current daemon started", and uses `-o short-iso` so no pt-BR month
  names are parsed.
- **Test hook**: `BT_DOCTOR_HISTORY=<file>` replaces the privileged history
  read with a fixture file.

### Tested vs. not tested (as of 995f960)

**Tested for real on xps:** `--help`, `diagnose`, `list` (all filters, `-q`,
piped and tty), name resolution and ambiguity, stdin chaining,
`reconnect` (ProtoArc, ~5 s), `reset power`, `fix` on a healthy adapter,
the `--history` parser against a fake store.

**Not tested yet** (syntax-checked and reviewed only):
- the interactive TUI and action menu, and `pick`
- `fix` levels rfkill and daemon, `reset rfkill|daemon|audio`
- `remove`, the real `pair` and scan & pair flows (the "yes every 2 s"
  feeder deserves one supervised run)
- the real `--history` path. It ran once by accident during testing (one
  polkit prompt at 07:48, read-only grep).

**Known nit:** a cache entry with an empty `Name=` gets an empty name.
Use a dashed-MAC placeholder.

## 3. Discussion: bt-doctor vs. bluetui

bluetui (Rust, ratatui, BlueZ over D-Bus) already does daily device
management well: scan, pair, connect, trust, remove, live updates. What
bt-doctor adds that bluetui can't:

- recovering a wedged stack (root-level resets, verified escalation)
- turning journal errors into a plain explanation and a fix
- a pairing agent that survives a daemon restart
- history of removed devices from the root-only store
- scriptable, chainable output
- restarting the audio stack (PipeWire/WirePlumber)

Options considered:

1. Keep bluetui, glue it to bt-doctor: a `bt` wrapper that relaunches
   bluetui after `fix`, plus a journal-watcher user service that sends a
   notification with a "Fix" button, plus menu/keybind entries.
2. **Fork bluetui into an enhanced version**: the user chose this.
3. Make bt-doctor's fzf TUI the main UI. Rejected because fzf can't do live
   state (streaming scan, connection changes) well.

## 4. Next: option 2 (enhanced bluetui), to be built on daisy

Starting points / open questions:

- Fork `pythops/bluetui` (Rust, ratatui, D-Bus via the `bluer` crate). Read
  its app/event structure before planning.
- Features to port from bt-doctor:
  - **Doctor panel**: the diagnose signatures and suggested fixes, live
    from the journal (journald via `sd-journal` crate, or spawn
    `journalctl -f -o json -u bluetooth`).
  - **Fix action**: the escalation ladder. Root steps via `pkexec`. Keep
    them as an external helper (could simply call `bt-doctor reset daemon`)
    so the TUI never runs as root.
  - **Agent resilience**: watch for bluetoothd restarts on D-Bus
    (NameOwnerChanged for `org.bluez`) and re-register the agent
    automatically. This is the "No agent available" failure we hit.
  - **History view**: removed or seen devices from `/var/lib/bluetooth`
    (privileged read through a helper).
  - **Per-device log pane**: journal lines for the selected device.
  - **HID-reconnect shortcut** for BLE HID devices whose input stalls
    (the ProtoArc touchpad case).
- Decide early which parts could go upstream as PRs (log pane, history,
  agent re-registration probably could; root resets probably not) and which
  stay fork-only.
- Keep `bt-doctor` as the CLI and scripting layer. The fork can shell out to
  it for privileged work.
