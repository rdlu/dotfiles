# LUKS FIDO2 unlock + greetd login

Migration guide: unlock the root LUKS volume with a FIDO2 security key
instead of typing the disk passphrase, and replace GDM with
[greetd](https://sr.ht/~kennylevinsen/greetd/) + `tuigreet` as the
display manager.

Completed on **daisy** (AMD). This guide is written to be applied to
**xps** (Intel). Both run CachyOS with [Limine](https://limine-bootloader.org/)
as the bootloader and niri as the compositor.

!!! warning "Read the rollback section first"

    A wrong initramfs or kernel cmdline leaves the machine unbootable,
    and a wrong display-manager swap leaves it without a graphical
    login. Both are recoverable, but only if you keep the escape hatches
    described in [Rollback](#rollback) — above all, **never remove the
    passphrase keyslot**.

## What you get

- Boot stops at a FIDO2 prompt: touch the key (and enter its PIN) instead
  of typing the LUKS passphrase.
- With **no key inserted**, boot falls straight through to the ordinary
  passphrase prompt — no hang, no timeout to sit through. Confirmed
  working on daisy.
- The passphrase keyslot survives untouched, forever.
- A minimal TUI greeter that hands straight to `niri-session`.

## Prerequisites

- A FIDO2 security key with a PIN configured (a YubiKey here).
- `systemd` ≥ 248, `cryptsetup`, `libfido2` — `libfido2` is declared in
  the manifest under the `security` category; the rest come with base.
- The initramfs must be **systemd-based**, not busybox. FIDO2 unlock is
  implemented by `systemd-cryptsetup`, which the classic `encrypt` hook
  does not use. See [Initramfs](#initramfs).
- Physical access and a way to boot rescue media.

## Identify the right partition

!!! danger "Check the device on each machine — do not copy daisy's"

    daisy has **two NVMe disks**: `nvme1n1` holds Linux, and `nvme0n1`
    holds an unrelated Windows install (NTFS). The LUKS partition is
    `nvme1n1p2` — *not* `nvme0n1`. Enrolling against the wrong device
    is destructive. xps has its own layout; verify before touching
    anything.

```sh
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT
```

Look for the partition with `FSTYPE=crypto_LUKS`. On daisy:

```text
nvme1n1                                         1,9T             disk
├─nvme1n1p1                                       2G vfat        part  /boot
└─nvme1n1p2                                     1,9T crypto_LUKS part
  └─luks-bfec6880-e8e5-4a60-88c5-d01df3987952   1,9T btrfs       crypt /
```

Record the partition path and its UUID — both are needed below:

```sh
export LUKS_PART=/dev/nvme1n1p2          # ← yours will differ
sudo cryptsetup luksUUID "$LUKS_PART"
```

Confirm the existing keyslots before adding one:

```sh
sudo cryptsetup luksDump "$LUKS_PART"
```

You should see at least one populated keyslot (your passphrase). Leave it
alone.

## Enroll the FIDO2 key

Insert the key, then:

```sh
sudo systemd-cryptenroll --fido2-device=auto "$LUKS_PART"
```

You will be asked for the existing passphrase (to authorise the change),
then for the key's PIN, then to touch the key. This **adds** a keyslot;
it does not replace the passphrase.

Verify a `systemd-fido2` token is now attached:

```sh
sudo cryptsetup luksDump "$LUKS_PART" | grep -A3 Tokens
```

!!! tip "Enrolling more than one key"

    Repeat the command per key. Enrolling a spare now is much cheaper
    than recovering a lost key later.

## Initramfs

FIDO2 unlock requires the `systemd` hook (which pulls in
`systemd-cryptsetup`) and `sd-encrypt` — the systemd equivalent of the
old `encrypt` hook. Edit `/etc/mkinitcpio.conf`.

daisy's working `HOOKS`, verbatim:

```sh
HOOKS=(base systemd autodetect microcode kms modconf block keyboard sd-vconsole sd-encrypt filesystems)
```

Two substitutions matter if you are coming from a stock busybox setup:

| Classic hook | systemd replacement |
| ------------ | ------------------- |
| `udev`       | `systemd`           |
| `encrypt`    | `sd-encrypt`        |
| `keymap consolefont` | `sd-vconsole`   |

`keyboard` must stay, or the key's PIN cannot be typed. Rebuild:

```sh
sudo mkinitcpio -P
```

Read the output rather than skimming it — a missing hook or module is
reported here, while the machine is still bootable.

## Plymouth

**This is the open decision for xps.** daisy has the `plymouth` package
installed but deliberately **left out of `HOOKS`**, so no boot splash is
active. The reason is friction, not incompatibility: the FIDO2 PIN
prompt comes from `systemd-cryptsetup` on the console, and with a splash
in front of it the prompt is easy to miss — you get a seemingly hung
splash while the key waits, unacknowledged, for a touch.

If you want to keep the splash on xps, plymouth is supported alongside
`sd-encrypt` — add the hook immediately after `systemd`:

```sh
HOOKS=(base systemd plymouth autodetect microcode kms modconf block keyboard sd-vconsole sd-encrypt filesystems)
```

Order matters: `plymouth` must come after `systemd` and before
`sd-encrypt`, so the splash owns the console before the unlock prompt is
issued and can render the password dialog itself.

Budget a test reboot specifically for this. If the prompt is swallowed,
either drop the hook (daisy's choice) or remove `quiet` from the cmdline
so the prompt is visible.

### Keeping the console readable

With no splash, the FIDO2 prompt competes with whatever else is printing
to the console — so boot-time warning noise stops being cosmetic and
starts being a usability problem. Audit it:

```sh
journalctl -b -p warning --no-pager | grep -v 'kernel:'
```

On daisy this turned up a stale `/etc/udev/rules.d/99-mouseless-input.rules`,
left behind by [mouseless](../wl-kbptr.md) after wl-kbptr replaced it. It was
emitting ~30 warnings per boot plus one deprecation notice, the last of
them landing about two seconds before the greeter started — close enough
that it read as though greetd were the source. Removed:

```sh
sudo rm /etc/udev/rules.d/99-mouseless-input.rules
sudo udevadm control --reload
```

!!! tip "Two lessons worth carrying to xps"

    **Attribute console messages by timestamp, not by position.** The
    last thing printed before a service starts usually is not that
    service. `journalctl -u <unit> -p warning` settles it — greetd's was
    empty across every boot.

    **Own your udev rules.** `pacman -Qo <file>` on anything in
    `/etc/udev/rules.d/` — a rule no package owns is one you wrote, and
    it will outlive the tool it was written for. Naming a login user as
    a device-node group (`GROUP="rdlu"`) is the specific pattern being
    deprecated; use `TAG+="uaccess"` or a real system group instead.

## Kernel cmdline

With Limine, the cmdline lives in `/etc/default/limine` — **not** in
per-entry files under `/boot`, which are regenerated. Edit
`KERNEL_CMDLINE[default]`.

daisy's working value, wrapped for readability (it is one line):

```sh
KERNEL_CMDLINE[default]="quiet nowatchdog rw rootflags=subvol=/@
  rd.luks.name=<UUID>=luks-<UUID>
  rd.luks.options=fido2-device=auto,token-timeout=1s
  systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0
  root=/dev/mapper/luks-<UUID>"
```

Substitute your own `luksUUID` for `<UUID>` in all three places. The
FIDO2-specific parts:

| Parameter | Why |
| --------- | --- |
| `rd.luks.name=<UUID>=luks-<UUID>` | Names the mapped device; `root=` must match. |
| `rd.luks.options=fido2-device=auto` | Enables FIDO2 unlocking for the volume. `auto` means the token's `hidraw` device is **auto-discovered as it is plugged in** — it selects *which device*, not an order of preference. `rd.luks.options=` is the analogue of crypttab's fourth (options) field, and is honored **only in the initrd**; `luks.options=` would apply in both. |
| `token-timeout=1s` | How long to wait *at most* for a configured security device to **show up**. Once it elapses, password authentication is attempted — which is why booting with no key inserted lands on the passphrase prompt immediately instead of stalling. Default is `30s`; `0` waits forever. Note it does **not** bound the token's PIN prompt. |
| `systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0` | **The parameter that made this setup usable.** Stops the double PIN prompt — see [below](#the-double-pin-prompt). Do not omit it. |

### The double PIN prompt

!!! success "If you take one thing from this guide, take this"

    `systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0` is what turned
    this from an annoying boot into a clean one on daisy. Everything else
    can be derived from the man pages; this cannot.

**Symptom.** FIDO2 unlock works, but every boot asks for the PIN
**twice** — most visibly on a keyless boot, where you get two prompts
before the passphrase fallback appears.

**Cause.** `systemd-cryptsetup` has two independent FIDO2 code paths: the
libcryptsetup **token plugin** (`libcryptsetup-token-systemd-fido2.so`),
and its own **built-in** implementation. It tries the plugin first, then
falls through to the built-in one — and each runs its own PIN prompt. The
enrollment is fine; you are simply being asked twice by two different
implementations.

**Fix.** Disable the plugin path so only the built-in one runs. Append to
`KERNEL_CMDLINE[default]` in `/etc/default/limine`, then rebuild:

```sh
systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0
```

```sh
sudo limine-mkinitcpio     # or: sudo limine-update && sudo mkinitcpio -P
```

It takes effect only **after a reboot** — the value must be in
`/proc/cmdline`, not merely in `/etc/default/limine`. Confirm with:

```sh
grep -o 'SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=[01]' /proc/cmdline
```

!!! info "Why the cmdline, and not deleting the .so"

    The other way to kill the plugin path is to remove
    `libcryptsetup-token-systemd-fido2.so` from the initramfs via a
    shadowed `/etc/initcpio/install/sd-encrypt`. The cmdline flag was
    chosen deliberately, for three reasons:

    - It is **rollback-able from the Limine menu** — press `e`, delete
      the parameter, boot. No rescue media needed if it misbehaves.
    - It needs **no re-sync** when Arch updates the `sd-encrypt` hook; a
      shadowed install file silently drifts from upstream.
    - It leaves the plugin in place on the **real root**, so
      `cryptsetup open` from a rescue USB still works with the key.

!!! note "`rd.luks.options=` here is unscoped, on purpose"

    The option list above carries **no `UUID=` prefix**, so it applies to
    any LUKS volume not named elsewhere and without an `/etc/crypttab`
    entry. Fine on a single-LUKS laptop like daisy. If xps ends up with
    a second encrypted volume, scope it explicitly instead:

    ```sh
    rd.luks.options=<UUID>=fido2-device=auto,token-timeout=1s
    ```

!!! note "The PIN prompt is expected"

    Even with the key enrolled, boot asks for the key's **PIN** (not the
    disk passphrase) before the touch. That is correct behaviour, not a
    failed enrollment. Fully keyless boot would require enrolling
    *without* a PIN, which weakens the setup to "possession of the key
    alone" — not done here.

Apply and rebuild the boot entries:

```sh
sudo limine-update
```

If `limine-update` is not present, the entries are regenerated by the
`limine-mkinitcpio-hook` on the next `mkinitcpio -P`.

### Verify before rebooting

```sh
sudo cryptsetup luksDump "$LUKS_PART" | grep -A3 Tokens   # token present
grep KERNEL_CMDLINE /etc/default/limine                    # UUIDs match
lsinitcpio -a /boot/initramfs-linux-cachyos.img | grep -i systemd
```

Then reboot with the key inserted, and with the passphrase to hand.

#### Rehearsing the unlock without rebooting

You can exercise the real FIDO2 path against the live volume, which is
much faster than a reboot cycle when tuning options:

```sh
sudo systemd-cryptsetup attach lukstest \
  /dev/disk/by-uuid/<UUID> - fido2-device=auto,token-timeout=1s
```

!!! danger "Ctrl+C at the passphrase prompt — never complete it"

    This creates a **second dm-crypt mapping over an already-mounted
    btrfs filesystem**. Let it prove the FIDO2 handshake (PIN prompt,
    touch, or the fallback), then abort at the passphrase prompt. Do not
    let it finish and do not mount the result.

Use `/dev/disk/by-uuid/` here rather than `/dev/nvme…` — NVMe
enumeration order is not stable.

## greetd + tuigreet

Independent of the LUKS work — do it as a separate step so a failure has
one obvious cause.

Install (both are declared in the manifest under `niri-wm`):

```sh
mise run pkg-install niri-wm
# or: paru -S --needed greetd greetd-tuigreet
```

Write `/etc/greetd/config.toml`. daisy's working config:

```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --cmd niri-session"
user = "greeter"

[initial_session]
command = "niri-session"
user = "rdlu"
```

!!! note "`initial_session` is autologin"

    That block logs `rdlu` straight into niri on the **first** boot of
    the session, skipping the greeter entirely — convenient on a
    single-user laptop with an encrypted disk, since the LUKS unlock is
    already the real authentication gate. Drop the block if you want the
    greeter every time.

This file is **not tracked in this repo**: it is root-owned, and the
stow tree only targets `$HOME`. It has to be written by hand on each
machine — hence its inclusion verbatim above.

Swap the display manager. Both halves in one command, so there is never
a window with neither enabled:

```sh
sudo systemctl disable gdm.service
sudo systemctl enable greetd.service
```

`display-manager.service` is a symlink managed by these two units; after
the swap it should resolve to greetd:

```sh
readlink -f /etc/systemd/system/display-manager.service
# → /usr/lib/systemd/system/greetd.service
```

Do **not** `systemctl start greetd` from inside a running graphical
session — it fights the live session for the VT. Reboot instead.

### On gdm

The `gdm` package has been dropped from `setup/packages.yaml`, but it is
deliberately **left installed on daisy** as a fallback. It is inert once
disabled (~5 MB, `Required By: None`), so there is no reason to hurry
its removal. To reinstate it in an emergency, see below. Once you are
confident, `sudo pacman -Rs gdm` removes it cleanly with no dependency
cascade.

## Verification

After a successful reboot:

```sh
loginctl show-session $XDG_SESSION_ID -p Type -p Service
# → Type=wayland
# → Service=greetd

sudo cryptsetup luksDump "$LUKS_PART" | grep -c systemd-fido2   # ≥ 1
```

## Rollback

Recovery paths, cheapest first.

**FIDO2 unlock fails, or the key is lost/forgotten.** Not really a
failure mode: boot without the key and the passphrase prompt appears
immediately, exactly as it did before enrollment. To drop the FIDO2 slot
afterwards:

```sh
sudo systemd-cryptenroll --wipe-slot=fido2 "$LUKS_PART"
```

**Initramfs is broken (no unlock prompt at all).** Boot the previous
kernel entry or the `-fallback` initramfs from the Limine menu, then
re-run `sudo mkinitcpio -P`. If neither boots, use rescue media,
unlock with the passphrase, `arch-chroot` in, and revert
`/etc/mkinitcpio.conf`.

**Greeter does not appear.** Switch to another VT with
`Ctrl+Alt+F2`, log in on the console, and either fix
`/etc/greetd/config.toml` or fall back:

```sh
sudo systemctl disable greetd.service
sudo pacman -S gdm          # only if already removed
sudo systemctl enable gdm.service
sudo reboot
```

**Nothing works.** Rescue media, unlock with the passphrase, `arch-chroot`,
`systemctl disable greetd`, revert the cmdline in `/etc/default/limine`,
`limine-update`, `mkinitcpio -P`.

## Applying to xps

| Item | daisy | xps |
| ---- | ----- | --- |
| LUKS partition | `nvme1n1p2` | **verify with `lsblk`** |
| Second disk | `nvme0n1` = Windows/NTFS | verify |
| Microcode | `amd-ucode` | `intel-ucode` — the `microcode` hook handles it, but confirm the package |
| Plymouth | installed, hook **omitted** | **undecided** — see [Plymouth](#plymouth) |
| Bootloader | Limine | Limine |
| Greeter | greetd + tuigreet | same |
| `SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0` | required | **required** — same double-prompt bug, see [The double PIN prompt](#the-double-pin-prompt) |

Everything else transfers unchanged. Do the LUKS half and the greetd
half as separate reboots.
