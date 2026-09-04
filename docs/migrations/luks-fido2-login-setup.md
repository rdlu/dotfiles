# LUKS FIDO2 unlock + greetd login

Migration guide: unlock the root LUKS volume with a FIDO2 security key
instead of typing the disk passphrase, and replace the stock display
manager with [greetd](https://sr.ht/~kennylevinsen/greetd/) + `tuigreet`.

Completed on **daisy** (AMD) and, since a subsequent debugging session,
**completed and verified on xps** (Intel, Dell XPS 9320, i7-1260P) —
greetd is the live display manager, plymouth is kept and renders the LUKS
prompt, and two YubiKeys unlock the root volume. Both run CachyOS with
[Limine](https://limine-bootloader.org/) as the bootloader and niri as
the compositor — but they diverge in enough places that every command
below is labelled per machine where it differs. The divergences are not
cosmetic: **the initramfs rebuild command, the display manager, and the
rollback path are all different on xps.**

Two later sections cover work that rides along with this migration
rather than being part of it —
[oo7 replacing gnome-keyring](#secret-service-oo7-replaces-gnome-keyring),
which autologin forces, and
[fingerprint auth for `sudo`/`pkexec` and the lock
screen](#fingerprint-for-sudo-polkit-and-the-lock-screen),
which is pure convenience and touches neither boot nor the greeter.

!!! warning "Read the rollback section first"

    A wrong initramfs or kernel cmdline leaves the machine unbootable,
    and a wrong display-manager swap leaves it without a graphical
    login. Both are recoverable, but only if you keep the escape hatches
    described in [Rollback](#rollback) — above all, **never remove the
    passphrase keyslot**. On xps the escape hatch is *not* a fallback
    initramfs (there isn't one); it is a Snapper snapshot you must take
    **before** editing `HOOKS`.

## What you get

- Boot stops at a FIDO2 prompt: touch the key (and enter its PIN) instead
  of typing the LUKS passphrase.
- With **no key inserted**, boot falls straight through to the ordinary
  passphrase prompt — no hang, no timeout to sit through. Confirmed
  working on daisy and on xps.
- The flip side of that immediacy: with `token-timeout=1s` the key has to
  be *already enumerated* when `systemd-cryptsetup` first looks. Plugged
  into a dock behind a hub chain it is not, and boot silently behaves as
  if no key existed — see
  [When boot ignores the key](#when-boot-ignores-the-key-token-timeout-and-usb-topology).
- The passphrase keyslot survives untouched, forever.
- A minimal TUI greeter that hands straight to `niri-session`.

## Prerequisites

- A FIDO2 security key with a PIN configured (a YubiKey here). On xps it
  enumerates as `/dev/hidraw1` — a Yubico OTP+FIDO+CCID device,
  `0x1050:0x0407`.
- `systemd` ≥ 248, `cryptsetup`, `libfido2` — `libfido2` is declared in
  the manifest under the `security` category
  (`setup/packages.yaml:259`); the rest come with base. xps has
  `libfido2` 1.17.0, `cryptsetup` 2.8.7, systemd 261.
- The initramfs must be **systemd-based**, not busybox. FIDO2 unlock is
  implemented by `systemd-cryptsetup`, which the classic `encrypt` hook
  does not use. See [Initramfs](#initramfs).
- Physical access and a way to boot rescue media.

!!! danger "None of this is tracked by the repo"

    Nothing in this repo tracks `/etc` — the stow tree targets `$HOME`
    only. `/etc/mkinitcpio.conf`, `/etc/default/limine` and
    `/etc/greetd/config.toml` are hand-written per machine, and **this
    document is their only record.** That is why every working value
    below is quoted verbatim rather than summarised, and why it is worth
    updating this page whenever one of them changes.

## Do it in two reboots, greetd first

The LUKS half and the greetd half are independent. Do them as **separate
reboots**, so a failure has exactly one plausible cause.

Prefer **greetd first**: it is by far the lower-risk half. A broken
greeter still leaves you a text VT (`Ctrl+Alt+F2`) and a working system;
a broken initramfs leaves you at a bootloader prompt with rescue media.
Get the cheap half landed and verified, then take on the disk.

## Identify the right partition

!!! danger "Check the device on each machine — do not copy daisy's"

    daisy has **two NVMe disks**: `nvme1n1` holds Linux, and `nvme0n1`
    holds an unrelated Windows install (NTFS). The LUKS partition is
    `nvme1n1p2` — *not* `nvme0n1`. Enrolling against the wrong device
    is destructive.

    **xps has a single NVMe** and no Windows install, so the numbering is
    shifted: the LUKS partition is `nvme0n1p2`. Copying daisy's device
    path onto xps would point at nothing on xps — and on any third
    machine it could point at the wrong disk. Verify with `lsblk` every
    time.

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

On xps:

```text
nvme0n1                                       953,9G             disk
├─nvme0n1p1                                       2G vfat        part  /boot
└─nvme0n1p2                                   951,9G crypto_LUKS part
  └─luks-be1ed90f-6dec-438d-95c3-fdc12d1a26e5 951,9G btrfs       crypt /
```

Record the partition path and its UUID — both are needed below:

```sh
export LUKS_PART=/dev/nvme1n1p2          # daisy
export LUKS_PART=/dev/nvme0n1p2          # xps
sudo cryptsetup luksUUID "$LUKS_PART"
```

xps's LUKS UUID is `be1ed90f-6dec-438d-95c3-fdc12d1a26e5`; it appears
three times in the kernel cmdline below.

Confirm the existing keyslots before adding one:

```sh
sudo cryptsetup luksDump "$LUKS_PART"
```

You should see at least one populated keyslot (your passphrase). Leave it
alone.

### What a bare header looks like

xps before enrollment — one keyslot, no tokens at all:

```text
Keyslots:
  0: luks2      PBKDF: argon2id   Time cost: 9   Memory: 1048576   Threads: 4
Tokens:
Digests:
  0: pbkdf2
```

An empty `Tokens:` section is the definitive "no FIDO2 enrolled yet"
signal. If yours is not empty, something is already enrolled — find out
what before adding more.

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
sudo cryptsetup luksDump "$LUKS_PART"
```

!!! tip "Enrolling more than one key"

    Repeat the command per key. Enrolling a spare now is much cheaper
    than recovering a lost key later.

### What a correct header looks like

daisy's, abridged — **two** YubiKeys enrolled alongside the passphrase:

```text
Keyslots:
  0: luks2      PBKDF: argon2id   Time cost: 11   Memory: 1048576   ← passphrase
  1: luks2      PBKDF: pbkdf2     Iterations: 1000                  ← FIDO2 key #1
  2: luks2      PBKDF: pbkdf2     Iterations: 1000                  ← FIDO2 key #2
Tokens:
  0: systemd-fido2   Keyslot: 1
  1: systemd-fido2   Keyslot: 2
```

Each token also carries:

```text
fido2-rp:                 io.systemd.cryptsetup
fido2-clientPin-required: true     ← why boot asks for the PIN
fido2-up-required:        true     ← why boot asks for a touch ("user presence")
fido2-uv-required:        false    ← no biometric verification
```

Those three flags are the authoritative answer to "why am I being asked
for a PIN *and* a tap" — the behaviour is recorded in the header at
enrollment time, not decided at boot.

!!! success "xps now matches, verified"

    xps's header has grown from the bare one above to exactly this
    shape: **3 keyslots** — slot 0 argon2id (the passphrase), slots 1
    and 2 pbkdf2/1000 — and **2 `systemd-fido2` tokens**, one per
    YubiKey, both carrying `fido2-clientPin-required: true`. Two keys
    enrolled, passphrase untouched.

!!! warning "`Iterations: 1000` on the FIDO2 slots is correct — do not 'fix' it"

    Next to the passphrase slot's argon2id at 1 GiB of memory, the FIDO2
    slots look catastrophically weak, and an audit will flag them.
    They aren't. Key-derivation hardening exists to make *low-entropy
    human passphrases* expensive to brute-force. A FIDO2 slot's input is
    a high-entropy secret derived from the token's HMAC — there is no
    dictionary to run against it, so stretching buys nothing.
    `systemd-cryptenroll` picks pbkdf2/1000 deliberately. Raising it only
    slows your own boot.

    The corollary matters more: those slots are exactly as strong as
    physical possession of the key plus its PIN. Keep the passphrase slot
    on a secret good enough to stand alone, since it is the one an
    attacker can actually attack offline.

## Initramfs

FIDO2 unlock requires the `systemd` hook (which pulls in
`systemd-cryptsetup`) and `sd-encrypt` — the systemd equivalent of the
old `encrypt` hook. Edit `/etc/mkinitcpio.conf`.

daisy's working `HOOKS`, verbatim:

```sh
HOOKS=(base systemd autodetect microcode kms modconf block keyboard sd-vconsole sd-encrypt filesystems)
```

xps starts from the stock busybox line at `/etc/mkinitcpio.conf:55` —
note it already carries `plymouth`, on the busybox path, after
`consolefont`:

```sh
# xps, before
HOOKS=(base udev autodetect microcode kms modconf block keyboard keymap consolefont plymouth encrypt filesystems)
```

and lands on daisy's line **plus** `plymouth`, moved up to directly after
`systemd` (see [Plymouth](#plymouth) for why it moves):

```sh
# xps, after
HOOKS=(base systemd plymouth autodetect microcode kms modconf block keyboard sd-vconsole sd-encrypt filesystems)
```

`MODULES=(crc32c)` is unchanged on both.

Two substitutions matter if you are coming from a stock busybox setup:

| Classic hook | systemd replacement |
| ------------ | ------------------- |
| `udev`       | `systemd`           |
| `encrypt`    | `sd-encrypt`        |
| `keymap consolefont` | `sd-vconsole`   |

`keyboard` must stay, or the key's PIN cannot be typed.

!!! warning "`plymouth-encrypt` has no place here"

    On the busybox path, a plymouth + LUKS setup uses
    `plymouth-encrypt` in place of `encrypt`. There is no
    `plymouth-sd-encrypt`: on the systemd path, `sd-encrypt` already
    talks to plymouth through `systemd-ask-password`. Neither the before
    nor the after line above contains `plymouth-encrypt`, and adding it
    would break the boot.

!!! note "Check `/etc/vconsole.conf` before you rely on `sd-vconsole`"

    `sd-vconsole` is what carries your console keymap into the initrd,
    and the FIDO2 **PIN is typed blind** at that prompt — no echo, no
    second chance to see what layout you are on. xps has:

    ```sh
    KEYMAP=br-abnt2
    XKBLAYOUT=br
    ```

    If your PIN contains a character that moves between the US and
    ABNT2 layouts, confirm the file exists and is correct *before* the
    reboot, not after.

### Rebuilding — the command differs per machine

!!! danger "`mkinitcpio -P` does nothing on xps"

    xps has **no mkinitcpio presets**: `/etc/mkinitcpio.d/` is empty.
    It uses the systemd `kernel-install` / Boot Loader Spec layout, so
    kernels and initramfs live under `/boot/<machine-id>/<kernel>/` —
    e.g. `/boot/1815827e1a1647c1b364cbb168e310e1/linux-cachyos/initramfs`.
    There is no `/boot/initramfs-linux-cachyos.img`.

    `sudo mkinitcpio -P` therefore builds **nothing at all**, exits 0,
    and leaves you believing the change took. Worse,
    `/usr/local/bin/mkinitcpio` — a shim shipped by
    `limine-mkinitcpio-hook` — shadows the real binary, runs it, and then
    warns that it "does not update Limine boot entries". Do not rely on
    answering that prompt correctly under pressure.

```sh
sudo mkinitcpio -P         # daisy
sudo limine-mkinitcpio     # xps  ← the only correct command here
```

`limine-mkinitcpio` calls
`/usr/share/libalpm/scripts/limine-mkinitcpio-install rebuild`, which
regenerates the initramfs for **every** installed kernel and then rewrites
and re-hashes the Limine entries. xps has two: `linux-cachyos` (7.2.2)
and `linux-cachyos-lts` (6.18.48).

Read the output rather than skimming it — a missing hook or module is
reported here, while the machine is still bootable.

!!! warning "`linux-cachyos-lts` is not a second opinion"

    Both kernels share the same `/etc/mkinitcpio.conf`. A bad `HOOKS`
    edit is rebuilt into **both** initramfs images by the same command,
    so booting the LTS entry recovers nothing. See
    [Rollback](#rollback) for what actually works on xps.

## Secure Boot and verified boot entries

!!! danger "xps only — and it constrains every command above"

    xps boots with **Secure Boot enabled and deployed**, managed by
    `sbctl` (Setup Mode disabled; Microsoft vendor keys present). daisy
    has no equivalent. On xps the initramfs is not merely a file the
    bootloader loads — it is a file the bootloader **verifies** before
    loading, and the verification data lives somewhere you must not
    hand-edit.

Check the state before touching anything:

```sh
sudo sbctl status
sudo cat /etc/limine-entry-tool.conf
```

xps's relevant settings:

```sh
ENABLE_VERIFICATION=yes    # every boot entry carries a content hash
ENABLE_UKI=no              # separate vmlinuz + initramfs, not a unified image
```

With `ENABLE_VERIFICATION=yes`, `/boot/limine.conf` records a **BLAKE2B
hash on every `path:` and `module_path:`** — the kernel and the initramfs
alike. Rebuilding the initramfs changes its bytes, which changes its hash,
which invalidates the recorded one. Limine then refuses to load it, and
you get a verification failure at the menu instead of a boot.

This is why `limine-mkinitcpio` is not merely a convenience wrapper on
xps: it is the step that rewrites the hashes to match the file it just
built. Any path that regenerates the initramfs without it —
`mkinitcpio -P` on a machine that *does* have presets, a hand-copied
image, an interrupted rebuild — leaves the two out of sync.

!!! danger "Never hand-edit `/boot/limine.conf`"

    `/etc/default/limine` has `ENABLE_ENROLL_LIMINE_CONFIG=yes`: the
    hash of `limine.conf` is itself enrolled into
    `/boot/EFI/Limine/limine_x64.efi`, which is then re-signed for
    Secure Boot. Editing `limine.conf` by hand desynchronises it from
    the enrolled hash and from the signature, and the failure surfaces
    at the next boot rather than at the edit.

    The cmdline is configured in `/etc/default/limine` and applied with
    `limine-update` / `limine-mkinitcpio`. That is the only supported
    entry point. `/boot/limine.conf` is generated output.

Two practical consequences:

- `/boot` on xps is mode **0700, root-only**. Every inspection command in
  this guide that touches `/boot` needs `sudo`, including the `lsinitcpio`
  verification below.
- Editing a boot entry from the Limine menu with `e` still works and is
  still the cheapest cmdline rollback — a menu edit is a one-shot
  override, not a write to the verified config.

## Plymouth

!!! info "Decided, differently, on each machine"

    - **daisy: omitted.** The `plymouth` package is installed but
      deliberately left out of `HOOKS`; no boot splash is active.
    - **xps: kept, and confirmed working.** The hook stays, moved from
      its busybox position to directly after `systemd`, and `splash`
      stays on the cmdline. The journal shows
      `Started Forward Password Requests to Plymouth`, which is the
      handoff that makes the splash render the LUKS prompt rather than
      swallow it.

    This was previously an open question. It is now settled per machine;
    the reasoning below is retained because it is what you need if the
    splash misbehaves on xps.

!!! tip "That journal line is the one to grep for"

    ```sh
    journalctl -b | grep 'Forward Password Requests to Plymouth'
    ```

    Present means `systemd-ask-password` and plymouth are wired
    together, so the PIN prompt has somewhere to be drawn. Absent, with
    `splash` on the cmdline, means the splash will look hung — and the
    fix is hook order, not the key.

The friction is real but narrower than it first looks, and it is worth
being precise about which half breaks:

- The FIDO2 **PIN prompt** goes through `systemd-ask-password`, which
  plymouth renders as its own password dialog. **This part works.**
- The **user-presence notification** — "touch your security key" — is a
  *message*, not a prompt. Plymouth has nowhere to put it, so it is
  swallowed. The splash then sits there looking hung while the key waits,
  unacknowledged, for a tap.

So the failure mode is not "the unlock is broken"; it is "the splash
gives you no reason to touch the key". Knowing that the tap is what it
wants is most of the fix.

Hook order matters: `plymouth` must come **after `systemd`** and
**before `sd-encrypt`**, so the splash owns the console before the unlock
prompt is issued and can render the password dialog itself.

```sh
HOOKS=(base systemd plymouth autodetect microcode kms modconf block keyboard sd-vconsole sd-encrypt filesystems)
```

Budget a test reboot specifically for this. If the splash sits there
doing nothing, mitigations in increasing order of cost:

1. **Press `Esc`.** Plymouth drops to its detail view and you see the
   real console messages, including the user-presence request. Costs
   nothing and needs no reboot — try this first, from the hung splash
   itself.
2. **Drop `quiet`, keep `splash`.** The kernel and systemd messages come
   back while the splash still renders; noisier, but the prompt is
   unmissable.
3. **Drop the hook** — daisy's choice. Only worth it if the first two
   are not enough, since it also costs you the splash on every ordinary
   boot.

xps runs `plymouth` 26.134.222 with the `cachyos-bootanimation` theme
(set in `/etc/plymouth/plymouthd.conf`). Other themes are installed and
selectable if the animation itself is part of the problem: `bgrt`,
`details`, `fade-in`, `glow`, `script`, `solar`, `spinfinity`,
`spinner`, `text`, `tribar`. `details` and `text` are essentially
permanent versions of the `Esc` view.

!!! note "Declare `plymouth` in the manifest"

    `plymouth` is **not** listed in `setup/packages.yaml` — it arrived
    on xps as a CachyOS base dependency, not as a choice. Now that
    keeping it *is* a deliberate decision, it should be declared, or a
    future base-package change can silently take the splash away with no
    record of why it was there.

The handoff to the greeter is already ordered correctly:
`greetd.service` carries `After=plymouth-quit-wait.service`, so the
splash tears down before the greeter takes the VT. Nothing to configure.

### Keeping the console readable

!!! note "daisy-specific — largely moot on xps"

    This subsection is about the no-splash case: with no plymouth, the
    FIDO2 prompt competes with whatever else is printing to the console,
    so boot-time warning noise stops being cosmetic and becomes a
    usability problem. With the splash kept on xps, it does not apply —
    and an audit of xps found nothing competing with the initrd prompt
    anyway. Its remaining boot warnings are all post-boot userspace
    noise (Nautilus GTK settings keys, a waybar SNI duplicate
    registration, `limine-snapper-sync`), none of which is on screen
    during unlock.

Audit it anyway if you are running without a splash:

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

!!! tip "Two lessons — and one correction from xps"

    **Attribute console messages by timestamp, not by position.** The
    last thing printed before a service starts usually is not that
    service. `journalctl -u <unit> -p warning` settles it — greetd's was
    empty across every boot.

    **Own your udev rules.** `pacman -Qo <file>` on anything in
    `/etc/udev/rules.d/`. Naming a login user as a device-node group
    (`GROUP="rdlu"`) is the specific pattern being deprecated; use
    `TAG+="uaccess"` or a real system group instead.

    **But "unowned" does not mean "stale".** daisy's heuristic — *a rule
    no package owns is one you wrote, and it will outlive the tool it was
    written for* — is too sharp. xps's `/etc/udev/rules.d/` contains
    exactly one file, `99-hide-ipu6-raw.rules`. It is package-unowned and
    it is **load-bearing**: it is the XPS 9320 IPU6 webcam workaround.
    Deleting it on the strength of the heuristic would break the camera.
    `pacman -Qo` tells you who shipped a rule, never whether it is still
    needed — that judgement is yours, per rule.

## Limine menu appearance

Untracked, hand-written, per-host — the same category as `/etc/pam.d`.
`/boot` is not in stow and **no package owns `/boot/limine.conf`** or
`/boot/limine-splash.png`; the theme was installed by hand from
[cachyos-limine-theme](https://github.com/diegons490/cachyos-limine-theme).
Reinstall that theme and you re-inherit everything below.

`limine-update` regenerates the entry blocks but **preserves the header**
above `/+CachyOS`, so edits there survive kernel updates. They do not
survive without a regeneration afterwards, though — see the warning at
the end.

xps's working header, after fixes:

```
term_palette: 1e1e2e;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4
term_palette_bright: 585b70;f38ba8;a6e3a1;f9e2af;89b4fa;f5c2e7;94e2d5;cdd6f4
term_background: 1e1e2e
term_foreground: cdd6f4
term_background_bright: 585b70
term_foreground_bright: cdd6f4
term_font_scale: 2x2
interface_branding:
wallpaper: boot():/limine-splash.png
```

!!! danger "The theme ships white-on-white — an upstream bug, not your config"

    As installed, the theme sets `term_background: ffffffff` and
    `term_background_bright: ffffffff` while the foreground is `cdd6f4`
    — Catppuccin Mocha's near-white text on a white background. The menu
    is legible only as faint ghosting.

    The palette's own base is `1e1e2e`, which is what the background was
    plainly meant to be. Fixed to `1e1e2e` / `585b70` (base / surface2)
    above.

    Six-digit values are deliberate. `ffffffff` is eight-digit
    `AARRGGBB`, where the alpha blends with the wallpaper — so the white
    could have come from the colour itself *or* from a light
    `limine-splash.png` showing through. An opaque six-digit value is
    correct under either reading and settles it without a reboot spent
    finding out.

!!! info "Font size is a resolution threshold, not a point size"

    Limine has no font-size setting; `term_font_scale` multiplies the
    built-in 8x16 glyph, each factor 1–8. From `CONFIG.md`:

    > If unset, the scaling follows the resolution: `1x1` below
    > 2560x1440, `2x2` from there, and `4x4` from 5120x2880.

    xps's internal panel is **1920x1200**, just under the cutoff, so it
    auto-selects `1x1` and the menu renders tiny. Its external display is
    2560x1600, *above* the cutoff — so the same machine renders the menu
    at two different sizes depending on what is plugged in. Setting
    `term_font_scale: 2x2` explicitly makes both consistent.

    A malformed value is silently ignored rather than failing to boot, so
    this is safe to experiment with.

!!! warning "Any edit here needs `limine-update`, or the machine will not boot"

    With `ENABLE_VERIFICATION=yes` and `ENABLE_ENROLL_LIMINE_CONFIG=yes`,
    `/boot/limine.conf` is hash-verified. Editing it by hand invalidates
    the enrolled BLAKE2B and the bootloader rejects the config. Always
    follow an edit with:

    ```sh
    pkexec limine-update
    ```

    and confirm `Config file BLAKE2B successfully enrolled` in the output
    before rebooting.

## Kernel cmdline

With Limine, the cmdline lives in `/etc/default/limine` — **not** in
per-entry files under `/boot`, which are regenerated (and, on xps,
hash-verified — see [Secure Boot](#secure-boot-and-verified-boot-entries)).
Edit `KERNEL_CMDLINE[default]`.

daisy's working value, wrapped for readability (it is one line):

```sh
KERNEL_CMDLINE[default]="quiet nowatchdog rw rootflags=subvol=/@
  rd.luks.name=<UUID>=luks-<UUID>
  rd.luks.options=fido2-device=auto,token-timeout=1s
  systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0
  root=/dev/mapper/luks-<UUID>"
```

xps starts from this — note the **`+=` append operator**, and the
`cryptdevice=` parameter:

```sh
# xps, before (one line)
KERNEL_CMDLINE[default]+="quiet nowatchdog splash rw rootflags=subvol=/@
  cryptdevice=UUID=be1ed90f-6dec-438d-95c3-fdc12d1a26e5:luks-be1ed90f-6dec-438d-95c3-fdc12d1a26e5
  root=/dev/mapper/luks-be1ed90f-6dec-438d-95c3-fdc12d1a26e5"
```

and lands here:

```sh
# xps, after (one line)
KERNEL_CMDLINE[default]+="quiet nowatchdog splash rw rootflags=subvol=/@
  rd.luks.name=be1ed90f-6dec-438d-95c3-fdc12d1a26e5=luks-be1ed90f-6dec-438d-95c3-fdc12d1a26e5
  rd.luks.options=fido2-device=auto,token-timeout=1s
  systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0
  root=/dev/mapper/luks-be1ed90f-6dec-438d-95c3-fdc12d1a26e5"
```

Three xps-specific points in that diff:

- **Keep `+=`.** daisy's example uses `=`; xps's file appends. Changing
  the operator is a separate, unrelated change — do not fold it in.
- **`splash` stays**, because plymouth is kept. On daisy it is absent.
- **`cryptdevice=` must go, in the same reboot as the `HOOKS` change.**

!!! danger "`cryptdevice=` is silently ignored by `sd-encrypt`"

    `cryptdevice=UUID=…:luks-…` is busybox-`encrypt` syntax. `sd-encrypt`
    does not read it — it does not warn, it does not fail, it simply
    never sees it. Swap `HOOKS` to `sd-encrypt` while leaving
    `cryptdevice=` in place and the initrd has **no idea which device to
    unlock**: you get dropped to an emergency shell with no prompt to
    answer.

    The `HOOKS` edit and the `cryptdevice=` → `rd.luks.name=` edit are
    one change. Make them together, rebuild once, reboot once.

Substitute your own `luksUUID` for `<UUID>` in all three places. The
FIDO2-specific parts:

| Parameter | Why |
| --------- | --- |
| `rd.luks.name=<UUID>=luks-<UUID>` | Names the mapped device; `root=` must match. Replaces `cryptdevice=`. |
| `rd.luks.options=fido2-device=auto` | Enables FIDO2 unlocking for the volume. `auto` means the token's `hidraw` device is **auto-discovered as it is plugged in** — it selects *which device*, not an order of preference. `rd.luks.options=` is the analogue of crypttab's fourth (options) field, and is honored **only in the initrd**; `luks.options=` would apply in both. |
| `token-timeout=1s` | How long to wait *at most* for a configured security device to **show up**. Once it elapses, password authentication is attempted — which is why booting with no key inserted lands on the passphrase prompt immediately instead of stalling. Default is `30s`; `0` waits forever. Note it does **not** bound the token's PIN prompt. One second is only enough if the key is on a **direct port** — see [When boot ignores the key](#when-boot-ignores-the-key-token-timeout-and-usb-topology). |
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

!!! tip "You can watch both prompts fire, in order, without rebooting"

    Run the rehearsal command **without** the `env` prefix — i.e. with
    the plugin path left enabled — and the two prompts appear one after
    the other, live:

    ```text
    🔐 Please enter LUKS2 token PIN:        ← the plugin
    🔐 Please enter security token PIN:     ← the built-in path, after the plugin fails
    ```

    That is the double prompt, reproduced on demand, and it is the
    cleanest proof that `SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0` is doing
    real work rather than being cargo-culted. It is also why the
    rehearsal has to be run with the variable set — see
    [Rehearsing the unlock](#rehearsing-the-unlock-without-rebooting).

!!! warning "xps is affected too — this is not optional there"

    It is worth confirming rather than assuming, and xps confirms:
    `/usr/lib/initcpio/install/sd-encrypt:29` copies
    `libcryptsetup-token-systemd-fido2.so` into the initramfs. The plugin
    is present, and the double prompt has since been **reproduced
    directly on xps** by running the rehearsal without the `env` prefix.
    Treat the flag as a required part of the cmdline change, not a fix to
    apply if the symptom shows up.

**Fix.** Disable the plugin path so only the built-in one runs. Append to
`KERNEL_CMDLINE[default]` in `/etc/default/limine`, then rebuild:

```sh
systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0
```

```sh
sudo mkinitcpio -P && sudo limine-update    # daisy
sudo limine-mkinitcpio                      # xps
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
      the parameter, boot. No rescue media needed if it misbehaves, and
      on a Secure Boot machine a menu edit does not disturb the enrolled
      config hash.
    - It needs **no re-sync** when Arch updates the `sd-encrypt` hook; a
      shadowed install file silently drifts from upstream.
    - It leaves the plugin in place on the **real root**, so
      `cryptsetup open` from a rescue USB still works with the key.

!!! note "`rd.luks.options=` here is unscoped, on purpose"

    The option list above carries **no `UUID=` prefix**, so it applies to
    any LUKS volume not named elsewhere and without an `/etc/crypttab`
    entry. That is correct on both machines: xps has a single LUKS
    volume, an `/etc/crypttab` that is comments only, and no
    `/etc/crypttab.initramfs` at all. If a machine ever gains a second
    encrypted volume, scope it explicitly instead:

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
sudo limine-update         # daisy — cmdline only
sudo limine-mkinitcpio     # xps — rebuilds initramfs *and* re-hashes entries
```

On xps, `limine-mkinitcpio` is the safe single command for any change to
either `/etc/mkinitcpio.conf` or `/etc/default/limine`, because it always
leaves the entry hashes matching the files on disk.

### Verify before rebooting

```sh
sudo cryptsetup luksDump "$LUKS_PART" | grep -c systemd-fido2   # one per key
sudo cryptsetup luksDump "$LUKS_PART" | grep -E 'Keyslot:|Tokens'
grep KERNEL_CMDLINE /etc/default/limine                          # UUIDs match

# daisy
lsinitcpio -a /boot/initramfs-linux-cachyos.img | grep -i systemd

# xps — Boot Loader Spec layout, and /boot is root-only
sudo lsinitcpio -a /boot/$(cat /etc/machine-id)/linux-cachyos/initramfs \
  | grep -i systemd
```

On xps, also confirm the cmdline no longer mentions `cryptdevice`:

```sh
grep -c cryptdevice /etc/default/limine    # → 0
```

Then reboot with the key inserted, and with the passphrase to hand.

#### Rehearsing the unlock without rebooting

You can exercise the real FIDO2 path against the live volume, which is
much faster than a reboot cycle when tuning options. **The `env` prefix
is not optional:**

```sh
sudo env SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0 systemd-cryptsetup attach \
  lukstest /dev/disk/by-uuid/<UUID> - fido2-device=auto,token-timeout=15s
```

!!! danger "Without `env …=0` the rehearsal tests the wrong code path and passes anyway"

    This guide previously gave the command without the `env` prefix.
    That version is worse than useless: it exercises the libcryptsetup
    **token plugin** — precisely the path that is *disabled* at boot —
    while boot uses systemd's **built-in** implementation.

    The reason is subtle. `systemd.setenv=` puts
    `SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0` into the **system manager's**
    environment, which is what `systemd-cryptsetup` inherits when PID 1
    runs it in the initrd. A command you type in a shell inherits your
    shell's environment, not the manager's — so the variable is simply
    absent, and the plugin runs.

    On xps this produced a confident "the rehearsal works" conclusion
    while boot was still failing. If you take a second thing from this
    guide, take this one.

**The prompt wording tells you which path you are on.** This is the
fastest diagnostic in the whole setup, and it needs nothing but reading
the line in front of you:

| Prompt | Path | Meaning |
| ------ | ---- | ------- |
| `🔐 Please enter LUKS2 token PIN:` | libcryptsetup **token plugin** | Wrong path — the variable did not reach the process |
| `🔐 Please enter security token PIN:` | systemd **built-in** | The path boot actually uses |

The built-in path is also the only one that says, when no key is
plugged in:

```text
Security token not present for unlocking volume root (lukstest), please plug it in.
```

The plugin instead prompts for a PIN **immediately**, before it has
checked whether any device exists at all. So "it asked me for a PIN with
nothing plugged in" is by itself proof you are on the plugin.

Running the un-prefixed command deliberately is still useful for one
thing: it reproduces the [double PIN prompt](#the-double-pin-prompt)
live and in order.

!!! danger "Ctrl+C at the passphrase prompt — never complete it"

    This creates a **second dm-crypt mapping over an already-mounted
    btrfs filesystem**. Let it prove the FIDO2 handshake (PIN prompt,
    touch, or the fallback), then abort at the passphrase prompt. Do not
    let it finish and do not mount the result.

!!! tip "Confirm the abort actually left nothing behind"

    Aborting is not the same as having aborted cleanly. Check for a
    stray mapping:

    ```sh
    sudo dmsetup ls
    ```

    You want to see only your real `luks-<UUID>` device and no
    `lukstest`. Verified clean on xps after several rehearsal runs, but
    check rather than assume — a leftover mapping over a mounted
    filesystem is exactly the thing this warning exists to prevent.

Use `/dev/disk/by-uuid/` here rather than `/dev/nvme…` — NVMe
enumeration order is not stable.

The rehearsal uses `token-timeout=15s` rather than the cmdline's `1s` on
purpose: a long window lets you start with **no key inserted**, watch the
"please plug it in" message, then insert the key mid-wait and see whether
hotplug detection works. On xps it does — see
[When boot ignores the key](#when-boot-ignores-the-key-token-timeout-and-usb-topology),
where that distinction is what separated a broken wait mechanism from a
merely too-short deadline.

### When boot ignores the key: token-timeout and USB topology

!!! warning "Symptom: boot goes straight to the passphrase prompt, key plugged in, every time"

    No FIDO2 prompt, no touch request, no pause. It reads as though
    `fido2-device=auto` were being ignored entirely — or as though the
    enrollment had not taken. Both enrollment and the cmdline can be
    perfectly correct and still produce this.

    The tell that it is *this* problem and not a broken setup: it fails
    **deterministically**, on every boot, rather than intermittently.

#### Diagnose it by correlating the initrd timeline

The technique matters more than the answer, because it generalises to
any "the initrd did not wait for X" question. The initrd journal is
retained, so compare **when `systemd-cryptsetup` looked for the token**
against **when the key's `hidraw` node appeared**:

```sh
journalctl -b -N -o short-precise
```

`-N` includes the initrd's own journal namespace; `-o short-precise`
gives sub-second timestamps, without which the whole comparison is
useless. From xps, boot starting at `13:28:41.967`:

```text
13:28:42.504  systemd-cryptsetup: Security token not present ... please plug it in
13:28:43.062  usb 3-1.4.2: new full-speed USB device ...
13:28:43.163  usb 3-1.4.2: New USB device found, idVendor=1050 (Yubico)
13:28:43.252  hid-generic ...: input,hidraw0 ...
13:28:43.848  systemd-cryptsetup: Timed out waiting for security device, aborting
```

Relative to boot start: cryptsetup checks at **+0.54s**, the key's
`hidraw` node is ready at **+1.29s**, and the deadline expires at
**+1.88s**. The key finished enumerating three quarters of a second
after it was looked for.

#### Root cause: two chained hubs

The YubiKey was in a dock / USB switch, which put it behind **two hubs**:

```text
root hub → GenesysLogic 3-1 → GenesysLogic 3-1.4 → port 2 → YubiKey
```

Both hubs have to enumerate before the key even starts, and `hidraw`
appearing is not the finish line either: udev still has to run
`/usr/lib/udev/fido_id`, which **probes the device over USB HID** in
order to set `ID_SECURITY_TOKEN=1`. A one-second deadline lands in the
middle of that sequence, so it misses *every* time.

```sh
lsusb -t     # shows the hub chain; count the levels between root and the key
```

!!! danger "Two things this is *not* — both were chased on xps, so you needn't"

    **Not missing udev rules.** They are in the initramfs. Confirm
    rather than assume:

    ```sh
    sudo lsinitcpio -l /boot/$(cat /etc/machine-id)/linux-cachyos/initramfs \
      | grep 'rules.d/'
    ```

    `60-fido-id.rules` and the `fido_id` binary are both present.

    **Not missing USB/HID modules.** Grepping the initramfs for
    `usbhid.ko`, `xhci_hcd.ko` or `usbcore.ko` finds nothing — and that
    is *correct*, because CachyOS builds them **into the kernel**. They
    are demonstrably working: the initrd journal contains
    `usbcore: registered new interface driver usbhid`. Never conclude
    "modules missing" from a `.ko` grep on a distro with builtins; check
    the journal for the driver registering instead.

#### The wait mechanism itself is fine

Proven with the corrected rehearsal at `token-timeout=15s`, starting
with **no key inserted** and plugging it in mid-wait:

```text
Security token not present for unlocking volume root (lukstest), please plug it in.
Asking FIDO2 token for authentication.
👆 Please confirm presence on security token to unlock.
Security token requires PIN.
```

systemd noticed the hotplug and carried on. So nothing is broken in the
detection path — the only problem was the deadline.

#### The trade-off, stated plainly

`token-timeout=` bounds how long to wait for a security device to
*appear*. Nothing can distinguish "no key present" from "key still
enumerating" — they look identical from inside the initrd. So **any**
increase to accommodate a slow or hub-attached key is paid as dead time
on every keyless boot, before the passphrase prompt shows up.

!!! failure "Superseded: `token-timeout=1s` plus a direct port is **not** sufficient"

    That was the original conclusion, and a later boot disproved it. The
    key was on a direct root-hub port (`usb 3-3`) and it still fell
    through to the passphrase. Kept here because the reasoning looks
    sound and someone will re-derive it otherwise.

#### Why a direct port was not enough: `hidraw` is not the finish line

The second failure, on **2026-09-04**, with the key in a laptop port —
no hubs anywhere in its path:

```text
06:59:01.458  systemd-cryptsetup: Security token not present ... please plug it in
06:59:01.625  usb 3-3: New USB device found, idVendor=1050 (Yubico)
06:59:01.696  hid-generic 0003:1050:0407.0002: hiddev96,hidraw1
              ── deadline ≈ 06:59:02.458 ──
06:59:02.538  systemd-cryptsetup: Timed out waiting for security device
```

The key enumerated **167ms** after cryptsetup looked, and its FIDO
`hidraw` node existed **762ms before** the deadline. Enumeration was
never the problem the second time.

What `fido2-device=auto` actually waits for is a device tagged
`ID_SECURITY_TOKEN=1`, and udev only sets that after running
`/usr/lib/udev/fido_id`, which probes the device over USB HID. That
probe is queued behind whatever else udev is doing — and the dock was
still enumerating (`3-1` hub, `3-1.1`, `3-10`) while plymouth started.
The device was present and unusable at the same time.

!!! info "Note which `hidraw` matters"

    The YubiKey presents two. `hidraw0` is interface 0, the OTP keyboard;
    `hidraw1` is interface 1, the FIDO one, and only that one carries
    `ID_SECURITY_TOKEN=1`. Confirm on a running system with:

    ```sh
    for h in /sys/class/hidraw/*; do
      udevadm info "$h" | grep -q ID_SECURITY_TOKEN=1 && echo "$h"
    done
    ```

    Seeing `hidraw0` appear in the boot log tells you nothing about
    whether the token is ready.

!!! danger "A third thing this is *not*: missing initramfs rules"

    Worth ruling out explicitly, because it produces an identical
    symptom and no timeout value would fix it. Check rather than assume:

    ```sh
    lsinitcpio -l /boot/$(cat /etc/machine-id)/linux-cachyos/initramfs \
      | grep -iE 'fido'
    ```

    On xps this lists `usr/lib/udev/fido_id`,
    `usr/lib/udev/rules.d/60-fido-id.rules`, `libfido2.so.1` and
    `libcryptsetup-token-systemd-fido2.so` — all present, supplied by the
    `sd-encrypt` hook. So the rules were there and it *still* timed out,
    which is what points at udev scheduling rather than a missing file.

    Note the earlier 15s rehearsal did **not** prove this: it ran in the
    booted system, against the root filesystem's udev rules, and never
    exercised the initrd path at all.

!!! success "Decision on xps: `token-timeout=5s`, key on a direct port"

    Applied 2026-09-04 in `/etc/default/limine`, followed by
    `limine-update`:

    ```sh
    rd.luks.options=fido2-device=auto,token-timeout=5s
    ```

    Five seconds rather than three because the quantity being covered is
    udev scheduling latency under load, which is far less predictable
    than the well-characterised 238ms of enumeration. Tighten it only
    against a measured successful unlock — the gap between the `hidraw1`
    line and `Asking FIDO2 token for authentication` is the real budget.

    The cost is unchanged and unavoidable: five seconds of dead time on
    every boot *without* the key, because the initrd cannot distinguish
    "no key present" from "key still enumerating."

    Keep the key on a direct port anyway. In the dock it sits behind two
    hubs whose second stage did not appear until **+11.8s**, which no
    sane timeout covers.

!!! warning "Snapshot entries keep the old timeout"

    `limine-snapper-sync` freezes each snapshot's cmdline at creation, and
    does not rewrite it. Every pre-existing snapshot entry in
    `/boot/limine.conf` still carries `token-timeout=1s`, so FIDO2 will
    likely fail when booting one and you will be on the passphrase —
    during recovery, which is the worst time to be surprised by it. New
    snapshots pick up the current value.

## greetd + tuigreet

Independent of the LUKS work, and the half to do **first** — see
[Do it in two reboots](#do-it-in-two-reboots-greetd-first).

!!! success "Done on xps"

    This half is complete and live on xps:
    `loginctl show-session` reports `Service=greetd` and `Type=wayland`,
    and `sddm` is inactive. The steps below are the record of how it got
    there, not pending work.

Both packages are declared in the manifest under `niri-wm`
(`setup/packages.yaml:95-96`). `greetd` 0.10.3 was already installed on
xps; `greetd-tuigreet` was the only missing piece (0.11.1-2.1, in
`cachyos-extra-v3` — a binary package, no AUR build):

```sh
paru -S --needed greetd-tuigreet    # narrow: just the missing piece
# or: mise run pkg-install niri-wm  # installs the WHOLE category, oo7 included
```

Write `/etc/greetd/config.toml`. This started as daisy's working config
— xps's was the stock default (`agreety --cmd /bin/sh`, user `greeter`,
vt 1), i.e. never configured, so this replaced it wholesale. What xps
runs now, comment block and all; the two absolute paths are explained in
[the wrapper section](#the-deprecation-warning-on-tty1-and-the-local-session-wrapper)
below, and daisy still has plain `niri-session` in both places:

```toml
# `niri-session-local` is a local copy of the niri package's
# /usr/bin/niri-session, patched to name the variables it hands to
# `systemctl --user import-environment`. The stock script uses the bare form,
# deprecated as of systemd 261, which prints a warning straight to tty1 at
# session start and again when niri exits. Absolute path on purpose: this
# user's PATH puts /usr/bin ahead of /usr/local/bin, so a same-name shadow
# would not win. Upstream fix pending: niri-wm/niri#254, PR #3572.
# Revert both commands to plain `niri-session` once niri ships it.

[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --cmd /usr/local/bin/niri-session-local"
user = "greeter"

[initial_session]
command = "/usr/local/bin/niri-session-local"
user = "rdlu"
```

The `greeter` system user already exists on xps (uid 959), and
`/usr/bin/niri-session` is present, as are `gnome.desktop` and
`niri.desktop` under `/usr/share/wayland-sessions/`.

!!! note "`initial_session` is autologin — and xps already autologins"

    That block logs `rdlu` straight into niri on the **first** boot of
    the session, skipping the greeter entirely — convenient on a
    single-user laptop with an encrypted disk, since the LUKS unlock is
    already the real authentication gate. Drop the block if you want the
    greeter every time.

    On xps this **preserved existing behaviour** rather than changing
    it: the session reported `Service=sddm-autologin` before the swap,
    so sddm was already logging the user straight in. Keeping
    `initial_session` made the swap invisible on a normal boot — the
    session now reports `Service=greetd`, and the greeter itself only
    shows up when you actually log out.

This file is **not tracked in this repo**: it is root-owned, and the
stow tree only targets `$HOME`. It has to be written by hand on each
machine — hence its inclusion verbatim above.

### The deprecation warning on tty1, and the local session wrapper

On xps, at niri session start and again when niri exits, tty1 shows:

```text
calling import-environment without a list of variables is deprecated
```

It comes from `/usr/bin/niri-session` (owned by the `niri` package,
currently 26.04-1.1), which does:

```sh
# Import the login manager environment.
systemctl --user import-environment
```

systemd 261 deprecated that bare, no-argument form. greetd runs
`niri-session` **directly** on vt1, so the script's stderr lands on the
console rather than in the journal — `journalctl -g import-environment`
finds nothing, which is why the line looks like it comes from nowhere.
It is printed once, at session start; it appears a second time at
shutdown only because tty1 is uncovered again when niri exits.

Upstream knows and has not fixed it: the tracking issue is
[niri-wm/niri#254](https://github.com/niri-wm/niri/issues/254)
([#3901](https://github.com/niri-wm/niri/issues/3901) was closed as a
duplicate), and [PR #3572](https://github.com/niri-wm/niri/pull/3572) is
**open, not merged**. No niri release carries the fix yet.

The workaround is `/usr/local/bin/niri-session-local`: a root-owned 0755
copy of the packaged script, identical except for one hunk —
`import-environment` is handed an explicit variable list, built with the
same awk-over-`ENVIRON` trick the script already uses in its dinit
branch further down:

```sh
# shellcheck disable=SC2046  # deliberate word splitting
systemctl --user import-environment $(awk 'BEGIN {
    for (v in ENVIRON)
        if (v ~ /^[A-Za-z_][A-Za-z0-9_]*$/ && v != "AWKPATH" && v != "AWKLIBPATH")
            print v
}')
```

Naming every variable is the same "import everything" behaviour, minus
the warning.

!!! note "Why a distinct name and an absolute path, not a PATH shadow"

    Two reasons, either one sufficient on its own:

    - This user's `PATH` puts `/usr/bin` **before** `/usr/local/bin`
      (mise + fish path construction), so a same-name
      `/usr/local/bin/niri-session` would not reliably win.
    - `niri-session` re-execs itself through the login shell —
      `exec bash -c "exec -l '$SHELL' -c '$0 -l $*'"` — so `$0` has to
      be absolute already for the re-exec to resolve.

    Hence the different filename, plus the full path in **both** greetd
    commands.

!!! warning "Known gap: the session menu still runs the stock script"

    `/usr/share/wayland-sessions/niri.desktop` still carries
    `Exec=niri-session`. Open tuigreet's session menu (the F-key list),
    pick "Niri", and you get the unpatched script and the warning back.
    The two paths actually used — the `initial_session` autologin and
    tuigreet's `--cmd` default — are both covered.

    Left alone deliberately: overriding it needs
    `tuigreet --sessions /usr/local/share/wayland-sessions:/usr/share/wayland-sessions`
    plus a local `niri.desktop`, and it is not established whether
    tuigreet dedupes same-named entries across those directories or just
    lists "Niri" twice.

!!! danger "The wrapper does not track the package — re-check it after every niri upgrade"

    A `niri` upgrade that changes `niri-session` leaves the wrapper
    silently running the old code, with no warning of any kind.

    `niri-session-wrapper` is what closes that gap. `check` compares the
    installed wrapper against the **current** stock script and exits
    non-zero once they have diverged; `install` regenerates the wrapper
    from the new stock script.

    ```sh
    ~/.local/bin/niri-session-wrapper check     # has it gone stale?
    ~/.local/bin/niri-session-wrapper install   # regenerate if it has
    ```

    `check` also reports when the workaround has become unnecessary —
    the stock script stops carrying the bare call the moment a niri
    release picks up the upstream fix. At that point run `remove`,
    which reverts both greetd commands to plain `niri-session` and
    deletes the wrapper.

What has actually been checked on xps:

- `sh -n` and `bash -n` are both clean on the wrapper.
- The awk enumeration produced **125** valid variable names, and zero
  malformed ones.
- `systemctl --user import-environment <NAME>` with an explicit name
  printed nothing and exited 0; the variable was then confirmed present
  in the manager environment, and unset again afterwards.
- `_` was confirmed to be a name systemd accepts.

**Confirmed by reboot on 2026-09-04.** tty1 came up clean. The session
really did run the wrapper rather than the stock script, which is worth
checking explicitly rather than inferring from a quiet console: greetd
logged `initial_session` as `/usr/local/bin/niri-session-local`, and the
session leader was `/bin/sh /usr/local/bin/niri-session-local -l`.

```sh
journalctl -b -u greetd.service | grep initial_session
pgrep -af niri-session
```

Note that the journal is *not* evidence either way here — the warning
goes to the console, never to the journal, so `journalctl -g
import-environment` returns nothing whether the fix works or not.
`/etc/greetd/config.toml.pre-wrapper` holds the config exactly as it was
before this change.

Not applied on daisy: it still runs the stock `niri-session` from both
greetd commands, and still prints the warning. The procedure below is
how to change that.

#### Applying it on daisy

Nothing here has been run on daisy — this is a procedure to follow, not
a record of work done. The cause is the section above; only the
mechanics follow.

The work is scripted as `niri-session-wrapper`, delivered by the
`scripts` stow package:

```sh
cd ~/.dotfiles
stow --no-folding --dotfiles -S scripts   # only if scripts isn't stowed yet
~/.local/bin/niri-session-wrapper install
```

Both steps in one, which is the same thing:

```sh
mise run niri-session-wrapper
```

The design point that makes this portable: `install` reads the **live**
`/usr/bin/niri-session` on the machine it runs on and applies the
substitution to *that*, instead of shipping a copy frozen from xps. So
daisy's niri version does not have to match xps's, and the same command
is what regenerates the wrapper after a later upgrade. It is idempotent
— re-running it is safe — and if the stock script no longer contains the
bare `import-environment` call, i.e. upstream shipped the fix, it says
so and installs nothing.

!!! note "daisy's `/etc/greetd/config.toml` is not the file quoted above"

    The config shown in [greetd + tuigreet](#greetd-tuigreet) is
    **xps's**, wrapper paths and all. daisy's differs, and the script
    does not overwrite it: it rewrites the two `command =` lines in
    place and leaves everything else daisy carries — `[terminal]`,
    `user =`, the tuigreet flags — exactly as it found them. The file is
    copied to `/etc/greetd/config.toml.pre-wrapper` first, and an
    existing backup is never clobbered. The result is validated as
    parseable TOML before the script reports success.

Verify in two stages. First, without touching the session:

```sh
~/.local/bin/niri-session-wrapper check
```

`check` is read-only and exits 0 only when every part holds: the
workaround is still needed, the wrapper exists, it is still in sync with
the current stock script, and **both** greetd commands point at the
absolute wrapper path. Anything short of that is a non-zero exit naming
the part that failed.

Then the real test, which needs a session boundary: log out and watch
tty1. A good result is the greeter coming up with no
`calling import-environment without a list of variables is deprecated`
line — neither at session start nor when niri exits.

!!! warning "Rolling it back on daisy"

    ```sh
    ~/.local/bin/niri-session-wrapper remove
    ```

    That points both `command =` lines back at plain `niri-session` and
    deletes `/usr/local/bin/niri-session-local`; the tty1 warning
    returns and nothing else changes. If the config needs to go back
    byte for byte, `/etc/greetd/config.toml.pre-wrapper` is the copy
    `install` took before its first edit. See also
    [Rollback](#rollback).

### Swap the display manager

!!! danger "It is sddm on xps, not gdm"

    daisy came from **gdm**. xps came from **sddm**: before the swap,
    `display-manager.service` resolved to
    `/usr/lib/systemd/system/sddm.service`, `sddm` was enabled, `gdm` was
    installed but already disabled, and `lightdm` was not installed at
    all. Running daisy's `systemctl disable gdm.service` on xps disables
    an already-disabled unit, reports success, and leaves **sddm still
    enabled** — so the next boot comes up in sddm and the swap looks
    mysteriously ineffective.

    Check first, every time:

    ```sh
    readlink -f /etc/systemd/system/display-manager.service
    ```

Both halves in one command, so there is never a window with neither
enabled:

```sh
sudo systemctl disable gdm.service  && sudo systemctl enable greetd.service   # daisy
sudo systemctl disable sddm.service && sudo systemctl enable greetd.service   # xps
```

`display-manager.service` is a symlink managed by these two units; after
the swap it should resolve to greetd:

```sh
readlink -f /etc/systemd/system/display-manager.service
# → /usr/lib/systemd/system/greetd.service
```

Do **not** `systemctl start greetd` from inside a running graphical
session — it fights the live session for the VT. Reboot instead.

### On the old display manager

**daisy — gdm.** The `gdm` package has been dropped from
`setup/packages.yaml`, but it is deliberately **left installed** as a
fallback. It is inert once disabled (~5 MB, `Required By: None`), so
there is no reason to hurry its removal. Once you are confident,
`sudo pacman -Rs gdm` removes it cleanly with no dependency cascade.

**xps — sddm.** Same policy: disable it, leave it installed. It is the
one-command way back to a graphical login if greetd or the tuigreet
config misbehaves, and it costs nothing sitting there disabled. xps also
still has a disabled `gdm` on top of that — a second fallback, and
equally harmless. Do not remove either until greetd has survived a few
days of ordinary use.

## Secret Service: oo7 replaces gnome-keyring

Independent of the LUKS work, but done in the same pass on both
machines: `gnome-keyring` is replaced by
[oo7](https://github.com/bilelmoussaoui/oo7), a Rust Secret Service
implementation that can unseal its keyring from the **TPM** instead of
from your login password. That matters here because greetd's
`initial_session` autologin never collects a password, so the
PAM-unlocks-the-keyring-at-login trick has nothing to work with.

!!! danger "`--noconfirm` silently fails this install"

    `oo7` declares `Conflicts With: gnome-keyring`, and `--noconfirm`
    answers **no** to the replace prompt, so the install aborts. Answer
    it explicitly:

    ```sh
    yes y | sudo pacman -S oo7
    ```

`oo7` provides `org.freedesktop.secrets`, so anything speaking the
Secret Service API (Chromium, Chrome, `libsecret` consumers) keeps
working without changes.

!!! warning "seahorse goes with it, and there is no GUI replacement"

    `seahorse` hard-depends on `gnome-keyring`, so it is removed in the
    same transaction. Nothing replaces it graphically — `oo7-cli` is the
    interface from here on, standing in for `secret-tool`.

    `qtkeychain-qt6` is unaffected: it wants the virtual
    `org.freedesktop.secrets`, which oo7 provides.

### Back up the keyring first — the migration is one-way

On its first start the daemon migrates the old **v0** keyring to **v1**,
consuming the original. There is no reverse path, so snapshot it before
you start the daemon:

```sh
cp -a ~/.local/share/keyrings ~/.local/share/keyrings.bak-$(date +%Y%m%d-%H%M%S)
sha256sum ~/.local/share/keyrings/login.keyring    # note it down
```

After a successful migration `~/.local/share/keyrings/v1/login.keyring`
exists and the v0 `login.keyring` is gone. Count your secrets before and
after — they must match.

### Seal the keyring password to the TPM

The vendor unit already carries the wiring:

```sh
systemctl --user cat oo7-daemon.service | grep ImportCredential
# → ImportCredential=oo7.keyring-encryption-password
```

So there is **no drop-in to write** — you only have to place a
correspondingly named encrypted credential where the user manager looks
for it:

```sh
mkdir -p ~/.config/credstore.encrypted
chmod 700 ~/.config/credstore.encrypted

printf '%s' 'YOUR-KEYRING-PASSWORD' \
  | systemd-creds encrypt --user --with-key=tpm2 \
      --name=oo7.keyring-encryption-password \
      - ~/.config/credstore.encrypted/oo7.keyring-encryption-password

chmod 600 ~/.config/credstore.encrypted/oo7.keyring-encryption-password
```

Three things must line up or the daemon starts locked: `--name=` must
equal the **filename**, the file must be `0600`, and the directory
`0700`. Confirm the TPM is actually usable first with
`systemd-analyze has-tpm2` (xps reports `yes` / `+firmware`).

!!! danger "A trailing newline seals into the credential and there is no error"

    `printf '%s'` above is load-bearing — it emits no trailing newline.
    Seal one in and the daemon offers a password one byte too long; the
    keyring simply stays locked, with nothing in the journal to say why.

    The cost of `printf` is that the password lands in shell history.
    Avoid both by having systemd prompt for it, where `-n` plays the same
    role:

    ```sh
    systemd-ask-password -n \
      | systemd-creds encrypt --user --with-key=tpm2 \
          --name=oo7.keyring-encryption-password \
          - ~/.config/credstore.encrypted/oo7.keyring-encryption-password
    ```

!!! success "Do not add PCR binding"

    `systemd-creds encrypt` binds to **no** PCRs unless you pass
    `--tpm2-pcrs=`, which is exactly what you want here: firmware and
    kernel updates cannot invalidate the credential.

    Adding PCR binding buys very little and will silently break unlock on
    the next UEFI update — the keyring just stops opening, with the same
    non-diagnostic symptom as every other failure in this section.

### Take `pam_gnome_keyring` out of the PAM stacks

With `gnome-keyring` gone, every `pam_gnome_keyring.so` line left in
`/etc/pam.d` refers to a module that no longer exists. Enumerate them
rather than working from a list — the set differs per host, because it
depends on which display managers that machine has had:

```sh
grep -rln pam_gnome_keyring /etc/pam.d/
```

On daisy that was six files — `gdm-password`, `gdm-autologin`,
`gdm-smartcard`, `gdm-fingerprint`, `ly` and `ly-autologin` — reflecting
a GDM history this machine does not share. Back up each file, then
comment its matching lines with a marker you can grep for later:

```sh
cp /etc/pam.d/FILE /etc/pam.d/FILE.pre-oo7
# then prefix each matching line with:  # [oo7]
```

!!! danger "Commenting a PAM line breaks relative jumps — this one costs an evening"

    In `gdm-fingerprint`, `gdm-smartcard` and `gdm-autologin` the line
    immediately **before** the keyring line is:

    ```
    auth [success=ok default=1] pam_gdm.so
    ```

    `default=1` means *skip the next 1 module*. Comment out the keyring
    line and that jump lands past the end of the auth stack. PAM logs
    `PAM bad jump in stack` to the journal and **fingerprint login
    fails** — while password login and `pkexec` keep working, because
    their stacks contain no such jump. The symptom therefore points
    everywhere except the actual cause.

    **Fix:** change `default=1` to `default=ignore` on those `pam_gdm.so`
    lines. It is equivalent now that there is no module left to skip.

    This is what the `bad jump` check in
    [Verification](#verification) is looking for.

!!! warning "`.pacnew` files reintroduce the commented lines"

    These are package-owned files. An update to the display manager
    writes a `.pacnew` containing the original `pam_gnome_keyring` line,
    and merging it carelessly puts the broken stack back — jump and all.
    Re-run the `grep -rln` above after any upgrade that touches a login
    manager.

!!! success "xps resolved this by deletion instead — 2026-09-04"

    The procedure above is daisy's, and it is correct there. xps needed
    none of it. The `grep -rln` found six files —
    `sddm`, `sddm-autologin`, `gdm-autologin`, `gdm-fingerprint`,
    `gdm-password`, `gdm-smartcard` — all with their keyring lines
    **uncommented**, so no relative jump had ever been disturbed and
    `journalctl -b | grep -i 'bad jump'` was empty.

    They also produced no `unable to dlopen` noise despite
    `pam_gnome_keyring.so` being absent, because nothing traverses those
    stacks: the machine boots through greetd, and a PAM stack only
    dlopens its modules when a service actually authenticates through it.

    `gdm` and `sddm` were both still installed, both disabled, and
    neither was in `setup/packages.yaml`. Removing them deleted all six
    files outright — strictly better than commenting lines and then
    repairing `default=1` jumps, because the trap becomes structurally
    impossible rather than merely avoided.

!!! danger "`-Rns` on a display manager drags the whole desktop stack with it"

    `pacman -Rns gdm sddm` initially proposed **20 packages, 364 MiB** —
    far past two unused greeters. Three of them were things the machine
    actively uses, and pacman said so in its own output:

    ```text
    :: xdg-desktop-portal optionally requires geoclue: Location portal
    :: ansible optionally requires python-argcomplete: shell completions
    ```

    plus `iio-sensor-proxy`, which is unrelated to display managers and
    is what exposes this laptop's accelerometer and ambient-light sensor.

    Protect what you are keeping **before** removing, so pacman stops
    treating it as a discardable dependency:

    ```sh
    pkexec pacman -D --asexplicit geoclue iio-sensor-proxy python-argcomplete
    pacman -Rs --print gdm sddm    # re-preview; no root needed
    ```

    That brought it to 15 packages, all genuinely GNOME-only
    (`gnome-shell`, `mutter`, `gnome-session`, `gnome-settings-daemon`,
    `libgdm`, `webkitgtk-6.0`, `egl-wayland` and their support libs).
    Verify each survivor's `Required By` before trusting the list.

!!! warning "`ibus` was gdm baggage, and it hid a real gap"

    `ibus` appeared in that removal list and looked worth saving — this
    machine is used for occasional Japanese input. It was not worth
    saving. `ibus` was a **gdm dependency**, its `Required By` was empty
    once gdm went, and **no engine was installed** alongside it: no
    `ibus-anthy`, no `ibus-mozc`, no `libkkc`. The framework was present
    and could not have done Japanese at all.

    `setup/packages.yaml` had the real answer under `input-method:` —
    `fcitx5` with `fcitx5-mozc` — and **none of those six packages were
    installed**. Japanese input had been quietly broken, and the removal
    is what surfaced it. Installed 2026-09-04; `ibus` removed.

    The lesson generalises: when a removal list contains something you
    believe you use, check what is actually installed behind it against
    the manifest before protecting it. A framework with no engine looks
    identical to a working setup in `pacman -Q`.

    Still outstanding: fcitx5 needs autostart and `XMODIFIERS=@im=fcitx`
    (niri speaks `text-input-v3` natively, but XWayland apps do not).
    Neither is in this repo yet.

### Point the portal at oo7

The packaged niri portal config still routes secrets at the now-absent
`gnome-keyring`. The override is tracked in this repo at
`niri/dot-config/xdg-desktop-portal/niri-portals.conf`:

```ini
org.freedesktop.impl.portal.Secret=oo7-portal;
```

Flatpaks that hold `talk=org.freedesktop.secrets` directly — Bitwarden
and Komikku among them — reach the daemon without going through the
portal at all, so they need nothing here.

### `pam_oo7` is not part of this

`/usr/lib/security/pam_oo7.so` exists and is tempting, but it is **not
used here** and is referenced in no file under `/etc/pam.d`. It works by
capturing `PAM_AUTHTOK` — your typed login password — and handing it to
the daemon over `/oo7-pam.sock`. It has **no TPM support** of its own,
and with autologin there is no `PAM_AUTHTOK` to capture. The
`systemd-creds` route above is what actually unlocks the keyring.

!!! warning "A locked collection reports zero items — that is not data loss"

    Two things will convince you the migration ate your secrets when it
    did not:

    - The collection path is capital **`Login`**, not `login`.
    - A **locked** collection reports `0` items. `oo7` starts locked
      until the credential unseals it.

    Check `Locked` before you panic, and do not "fix" it by unlocking
    with a guessed password — that creates an empty unlocked collection
    that masks the real one until you restart the daemon.

### Optional hardening, not done on either host

Rotate the keyring to a random password held only in the TPM credential.
That fully decouples it from the login password — at present the two
merely happen to be equal, which is a coincidence the design does not
require and nothing enforces.

!!! failure "The superseded approach — do not go back to it"

    Before the credential existed, the Login keyring password was set
    **blank** via Seahorse so it would auto-unlock. That leaves every
    secret in plaintext on disk, and it regressed **twice**, because:

    ```
    password optional pam_gnome_keyring.so use_authtok
    ```

    silently re-encrypted the blank keyring on any password change.

    This is structurally the same bug described in
    [`pam_oo7` is not part of this](#pam_oo7-is-not-part-of-this) — a
    `password` stack that re-keys the keyring behind your back. The
    credential exists precisely so the keyring password is independent of
    the login password.

## Fingerprint for sudo, polkit, and the lock screen

Purely a convenience layer, and deliberately **not** wired into boot or
the display manager — the Goodix sensor never unlocks the disk and never
stands in for the greeter. It covers `sudo`, the polkit dialog and the
`swaylock` screen, and nothing that runs before your session does.

Enroll, then confirm — one `fprintd-enroll` run per finger:

```sh
fprintd-enroll
fprintd-list "$USER"
# → Fingerprints for user rdlu on Goodix MOC Fingerprint Sensor (press):
# →  - #0: right-index-finger
# →  - #1: right-middle-finger
```

### Stock `pam_fprintd` makes the polkit dialog unusable

**Symptom.** With `pam_fprintd.so` first in the stack, the polkit GUI
dialog — `pkexec` and every desktop authentication prompt — swallows the
password. You type it, press Enter, and nothing happens until the
fingerprint attempt times out some ten seconds later; only then is the
password looked at.

**Cause.** It is documented behaviour, in `man pam_fprintd` under
LIMITATIONS:

```text
The PAM stack is by design a serialised authentication, so it is not
possible for pam_fprintd to allow authentication through passwords and
fingerprints at the same time. It is up to the application using the PAM
services to implement separate PAM processes and run separate
authentication stacks separately. This is the way multiple
authentication methods are made available to users of gdm for example.
```

`pam_fprintd` holds the stack. `pam_unix` cannot issue its
`PAM_PROMPT_ECHO_OFF` until fprintd returns — a match, a non-match with
`max-tries` exhausted, or the timeout — so what you typed just sits in
the agent helper's pipe with nothing reading it.

!!! info "The polkit agent cannot do gdm's trick — checked, not assumed"

    The man page's escape route is for the *application* to run separate
    PAM processes with separate stacks. `polkit-kde-authentication-agent-1`
    does not: its binary contains zero `fingerprint` or `fprint` strings,
    and it runs a single serial `polkit-agent-helper-1` per attempt. The
    journal shows the consequence — the only thing that reaches the
    dialog is `showInfo → "Place your finger on the fingerprint reader"`,
    a `PAM_TEXT_INFO` message, and never a prompt.

### The fix: `pam_fprintd_grosshack`

Replace the stock module with `pam_fprintd_grosshack.so` from the AUR
package `pam-fprint-grosshack`, already declared in the manifest under
`security` (`setup/packages.yaml:260`). It installs exactly one file,
`/usr/lib/security/pam_fprintd_grosshack.so`.

It issues a **real** `PAM_PROMPT_ECHO_OFF`, with the prompt text
`Enter Password or Place finger on fingerprint reader: `, while scanning
the sensor concurrently — so the password field is live from the first
moment and the finger still works.

One line at the **top** of the auth stack in each of two files:

```
auth		sufficient	pam_fprintd_grosshack.so	max-tries=3 timeout=30
```

- `/etc/pam.d/sudo` — ships in `sudo`, so back it up before editing.
- `/etc/pam.d/polkit-1` — has **no** file in `/etc/pam.d` by default;
  copy the vendor stack from `/usr/lib/pam.d/polkit-1` and prepend the
  line. This is the one that covers `pkexec` and every GUI authentication
  dialog.

!!! info "Why `sufficient` is safe — grosshack never checks the password"

    It does not validate the password itself. Its only PAM calls are
    `pam_get_item`/`pam_set_item`, `pam_prompt`, `pam_get_user` and
    `pam_syslog`; there is no `crypt` or shadow linkage in it at all.
    What it does with what you typed is stash it as `PAM_AUTHTOK` — and
    the `pam_unix.so try_first_pass` line already in `system-auth` does
    the real check further down the stack. A `sufficient` grosshack line
    therefore cannot short-circuit to success on a password nothing
    verified. The journal evidence below is exactly that property being
    exercised.

### Why `max-tries=3 timeout=30` and not `max-tries=1 timeout=10`

The old tight bound existed for one reason: keeping the fallback quick
for non-interactive `sudo`. That rationale is void here — grosshack's
prompt fails immediately when there is no usable PAM conversation,
measured at **17 ms** for `sudo -n true`.

`max-tries=1` was worse than merely unnecessary. A single misread press
retired the fingerprint option for that attempt and dropped the dialog
to a bare `Password: ` prompt. Three tries and thirty seconds cost
nothing and stop that.

### Verified on the live machine

From `journalctl` across a set of `pkexec` authentications with the
module in place:

- The request `Enter Password or Place finger on fingerprint reader: `
  arrives **0.5 s** after auth starts — the password field is live
  immediately, which is the whole point of the swap.
- `fprintd: Verification was in progress, stopping it` — typing the
  password **aborts** the in-flight verify instead of queueing behind
  it.
- Wrong password → `pam_unix(polkit-1:auth): authentication failure` →
  `Completed: false`. Rejected by `pam_unix`, not by grosshack. No
  bypass.
- Correct fingerprint → `Completed: true`, with no `pam_unix` failure.

!!! warning "Keep a root shell open while editing PAM"

    A malformed `/etc/pam.d/sudo` locks you out of `sudo`. Edit with an
    already-authenticated `sudo -i` shell open in another terminal, and
    test in a third before closing either.

!!! danger "An out-of-tree fork, in the auth path of both `sudo` and `polkit`"

    `pam-fprint-grosshack` is a fork of `pam_fprintd`: version **0.3.0**,
    upstream last modified **2022-07-27**. After this change it sits in
    the auth path for **both** `sudo` and `polkit-1`, so a `pam` or
    `fprintd` ABI bump can take out privilege escalation on the whole
    machine. **Re-test after every `pam` or `fprintd` update**, and treat
    it as a thing to check after a big system upgrade rather than
    something that quietly keeps working.

    The two paths are each other's escape hatch: a working `pkexec` still
    gets you root if `sudo` breaks, and a working `sudo` lets you repair
    `/etc/pam.d/polkit-1` if the dialog breaks. Change one file, test it,
    then change the other — never lose both at once.

### The lock screen takes the opposite ordering, and no grosshack

`/etc/pam.d/swaylock`, in full — `pam_unix` first, stock `pam_fprintd`
second:

```
auth sufficient pam_unix.so try_first_pass
auth sufficient pam_fprintd.so timeout=10
auth include    login
```

Two paths, separated by the ordering alone:

- **A typed password.** `pam_unix.so try_first_pass` matches on the
  first line and the screen unlocks instantly. The reader is never
  touched.
- **A bare Enter on an empty field.** `pam_unix` fails fast on the empty
  input and falls through to `pam_fprintd.so timeout=10`, which arms the
  sensor for ten seconds. The empty Enter **is** the gesture that arms
  the reader.

!!! info "Why the order is inverted here — the polkit race does not exist"

    In the polkit dialog the password field is live *before* you submit,
    so a waiting `fprintd` and a typed password genuinely compete for
    the one serialised PAM conversation. That race is the entire reason
    for grosshack.

    `swaylock` starts the PAM conversation **only on submit**. By the
    time PAM runs you have either typed a password or you have not —
    there is nothing to compete over. Ordering alone separates the two
    paths, and grosshack buys nothing.

!!! danger "Do not put grosshack at the top of the `swaylock` stack"

    It does not merely fail to help — it breaks the fingerprint path
    outright. `swaylock`'s conversation hands the empty buffer back
    immediately; grosshack reads that as a submitted password, aborts
    the in-flight scan, and the reader never arms. The password still
    works, so the stack looks half-fine while the finger does nothing.

    Everything above about grosshack applies to `sudo` and `polkit-1`
    and stops there.

!!! warning "`ignore-empty-password` must stay **absent** from the swaylock config"

    In `niri/dot-config/swaylock/config` — verified absent. With it set,
    `swaylock` swallows the empty submit, PAM never starts at all, and
    the reader appears completely dead while the password still works.
    That symptom sends you debugging `fprintd`, where nothing is wrong.

!!! info "`/etc/pam.d/swaylock` is not in the repo — hand-write it per host"

    It is a system file outside stow, so the dotfiles repo does not
    carry it. It *is* in the `swaylock-effects-git` package's `backup`
    array, so pacman preserves your edits and drops a `.pacnew`
    alongside on update rather than clobbering them — check for one
    after upgrades.

!!! info "`swaylock` is not setuid — `unix_chkpwd` is"

    `/usr/bin/swaylock` is `-rwxr-xr-x root root`. `pam_unix` still
    works because it delegates to the setuid-root helper
    `/usr/bin/unix_chkpwd` (`-rwsr-sr-x`). If password unlock ever
    starts failing with authentication errors, check that helper's mode
    before touching anything in `swaylock`.

!!! warning "Do not switch lockers, and do not add a per-second clock"

    Both break screen blanking, for the same reason. `swaylock` draws a
    **static** surface, so the display still DPMS-blanks while locked.
    `hyprlock` and the `rustlock` fork both render continuously, which
    keeps the panel lit under niri's session-lock surface and defeats
    swayidle's `power-off-monitors`. That is a niri limitation (issues
    #205 / #2439), not a misconfiguration — no locker config fixes it.

    The same reasoning fixes the clock at minute resolution
    (`timestr=%H:%M`). A per-second clock reintroduces the continuous
    redraw and the screen stops blanking, which is a battery problem
    disguised as a cosmetic preference.

!!! info "A lockout gives no on-screen explanation"

    `swaylock` discards PAM text, so when `faillock` locks the account
    the lock screen simply stops accepting input — no message, no reason.
    `show-failed-attempts` in the config is the mitigation.

    The `rdlu/rustlock` fork (branch `pam-message-display`) renders PAM
    `text_info`/`error_msg` and synthesizes an "Account locked" notice.
    It is kept as a **testing tool, not the active locker**, for the
    blanking reason above.

    On xps, `/etc/security/faillock.conf` sets only `deny = 6`; with
    `unlock_time` unset the effective value is the **600s default**. Note
    daisy's notes claim `unlock_time=10` — that is unverified and should
    be checked there rather than assumed, since ten seconds would be a
    surprisingly permissive lockout.

    ```sh
    faillock --user "$USER"           # inspect counters
    faillock --user "$USER" --reset   # clear them
    ```

This stack is **verified on daisy**, which has run it for a while, and
was applied and confirmed working on xps on **2026-09-03** — all three
paths exercised by hand: typed password, empty Enter then finger, and a
deliberately wrong password.

It reached that state the hard way. grosshack went in here first, on the
reasoning that if it beat stock `pam_fprintd` for the polkit dialog it
should beat it everywhere. It does not, for the reason in the `!!! info`
above, and the fingerprint path broke exactly as the `!!! danger` block
describes. Reverting to daisy's ordering fixed it.

## Verification

After a successful reboot:

```sh
loginctl show-session $XDG_SESSION_ID -p Type -p Service
# → Type=wayland
# → Service=greetd          (was sddm-autologin on xps, gdm on daisy)

sudo cryptsetup luksDump "$LUKS_PART" | grep -c systemd-fido2   # ≥ 1
grep -o 'SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=[01]' /proc/cmdline # → …=0
```

On xps, also re-check that Secure Boot survived the rebuild:

```sh
sudo sbctl status          # Secure Boot: enabled, Setup Mode: disabled
```

If you also did the [oo7](#secret-service-oo7-replaces-gnome-keyring)
and [fingerprint](#fingerprint-for-sudo-polkit-and-the-lock-screen)
work, five more checks — all five pass on xps:

```sh
systemctl --user is-active oo7-daemon.service            # → active
busctl --user get-property org.freedesktop.secrets \
  /org/freedesktop/secrets/collection/Login \
  org.freedesktop.Secret.Collection Locked               # → b false
oo7-cli list | grep -c '^\['                             # item count, vs your pre-migration count
test -f ~/.local/share/keyrings/v1/login.keyring && echo migrated
journalctl -b | grep -ci 'bad jump'                       # → 0
```

The `Locked` check is the one that matters: `b false` means the TPM
actually unsealed the credential. `b true` with a healthy daemon means
the credential name, file mode, or directory mode is wrong.

The `bad jump` check reads the **journal**, not command output — PAM
reports a malformed stack there and nowhere else. Grepping the output of
`sudo` itself always looks clean and proves nothing.

!!! success "xps, verified on the live machine"

    Every one of these has been checked on the running system. The
    one item still outstanding is called out at the end of the list:

    - `loginctl show-session` → `Service=greetd`, `Type=wayland`;
      `sddm` inactive.
    - Plymouth kept and working — the journal has
      `Started Forward Password Requests to Plymouth`, so the splash is
      what renders the LUKS prompt.
    - 3 keyslots (0 argon2id passphrase, 1 and 2 pbkdf2/1000 FIDO2) and
      2 `systemd-fido2` tokens, both `fido2-clientPin-required: true`.
    - Cmdline carries `rd.luks.name=`,
      `rd.luks.options=fido2-device=auto,token-timeout=1s`,
      `systemd.setenv=SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0`, and
      `splash`; no `cryptdevice=`.

    Still **unverified**: the key must sit in a **direct laptop port**,
    not the dock — behind the dock's hub chain `hidraw` appears at
    +1.29s, well past the +0.54s check with `token-timeout=1s`, so the
    key is ignored on every boot. That was diagnosed from the initrd
    journal but **not yet re-tested across a reboot from a direct
    port**; `lsusb -t` still shows the key two hubs deep. See
    [When boot ignores the key](#when-boot-ignores-the-key-token-timeout-and-usb-topology).

## Rollback

Recovery paths, cheapest first.

**FIDO2 unlock fails, or the key is lost/forgotten.** Not really a
failure mode: boot without the key and the passphrase prompt appears
immediately, exactly as it did before enrollment. To drop the FIDO2 slot
afterwards:

```sh
sudo systemd-cryptenroll --wipe-slot=fido2 "$LUKS_PART"
```

**Boot ignores the key — straight to the passphrase prompt, every
time.** Not a rollback: the key is almost certainly enumerating too
slowly, not misconfigured. Check the USB topology with `lsusb -t`, and
correlate the initrd journal (`journalctl -b -N -o short-precise`) to see
whether `hidraw` appeared after `systemd-cryptsetup` had already given
up. Prefer a **direct laptop port** over a dock or hub. Full workup in
[When boot ignores the key](#when-boot-ignores-the-key-token-timeout-and-usb-topology).

**The cmdline is wrong (boots, but to an emergency shell).** Edit the
entry from the Limine menu with `e`, fix or delete the offending
parameter, and boot once. That is a one-shot override — it does not
touch the verified config on disk — so it is safe even under Secure
Boot. Then fix `/etc/default/limine` properly from the booted system.

**Initramfs is broken (no unlock prompt at all).** This is where the two
machines diverge most.

*daisy:* boot the previous kernel entry or the `-fallback` initramfs from
the Limine menu, then re-run `sudo mkinitcpio -P`.

!!! danger "xps has no fallback initramfs, and no usable second kernel"

    There is exactly **one** `initramfs` per kernel under
    `/boot/<machine-id>/<kernel>/` — no `-fallback` image exists to boot.
    And `linux-cachyos-lts` is not an escape hatch either: it shares
    `/etc/mkinitcpio.conf` and is rebuilt by the same
    `limine-mkinitcpio` run, so a bad `HOOKS` edit breaks both kernels
    identically.

    The real escape hatch on xps is the **Snapshots** entries generated
    by `limine-snapper-sync`. Those reference older initramfs and vmlinuz
    blobs preserved under `/boot/<machine-id>/limine_history/`, keyed by
    sha256 — so a snapshot entry boots the initramfs *as it was*, not a
    rebuild of the current config.

    **Take a snapshot deliberately, immediately before the `HOOKS` edit.**
    Do not assume the automatic timeline has a recent enough one.

!!! warning "Reconcile the snapshot limit before relying on it"

    `limine-snapper-sync` on xps currently warns, hourly:

    ```text
    Snapshot limit mismatch: 50 Snapper snapshots exceed configured
    MAX_SNAPSHOT_ENTRIES=8
    ```

    Only 8 snapshots get boot entries while Snapper holds 50. Which 8 is
    not something to discover during a failed boot. Since snapshots are
    *the* rollback path on xps, settle this — raise
    `MAX_SNAPSHOT_ENTRIES`, or prune Snapper — **before** the initramfs
    change, and then confirm your deliberate pre-change snapshot actually
    has an entry in the Limine menu.

If no entry boots on either machine: rescue media, unlock with the
passphrase, `arch-chroot` in, revert `/etc/mkinitcpio.conf`, and rebuild
with the machine's own command (`mkinitcpio -P` on daisy,
`limine-mkinitcpio` on xps).

**Greeter does not appear.** Switch to another VT with
`Ctrl+Alt+F2`, log in on the console, and either fix
`/etc/greetd/config.toml` or fall back to the previous display manager:

```sh
sudo systemctl disable greetd.service
sudo systemctl enable gdm.service     # daisy
sudo systemctl enable sddm.service    # xps
sudo reboot
```

**The greeter is fine, but the session wrapper is not — a niri upgrade
moved out from under it, or you want it gone.** Point both `command =`
lines in `/etc/greetd/config.toml` back at plain `niri-session` and
delete `/usr/local/bin/niri-session-local`; the tty1 deprecation warning
comes back and nothing else changes. `/etc/greetd/config.toml.pre-wrapper`
is that config as it was before the wrapper went in. See
[the wrapper section](#the-deprecation-warning-on-tty1-and-the-local-session-wrapper).

**Nothing works.** Rescue media, unlock with the passphrase,
`arch-chroot`, `systemctl disable greetd`, revert the cmdline in
`/etc/default/limine`, then `limine-update` + `mkinitcpio -P` (daisy) or
`limine-mkinitcpio` (xps).

## daisy vs xps

The **xps** column is verified by direct inspection of this machine. The
**daisy** column is carried over from what this guide already recorded —
where daisy's value was never written down, the cell says so rather than
guessing.

| Item | daisy (AMD) | xps (Intel, XPS 9320) |
| ---- | ----------- | --------------------- |
| LUKS partition | `nvme1n1p2` | `nvme0n1p2`, UUID `be1ed90f-6dec-438d-95c3-fdc12d1a26e5` |
| Second disk | `nvme0n1` = Windows/NTFS | **none** — single NVMe, so the numbering shifts |
| Microcode | `amd-ucode` | `intel-ucode` (installed; `microcode` hook already in `HOOKS`) |
| Plymouth | installed, hook **omitted** | **kept** — hook moved after `systemd`, `splash` retained. See [Plymouth](#plymouth) |
| Display manager | gdm → greetd | **sddm** → greetd (gdm present but already disabled) |
| Autologin before the swap | not recorded | `sddm-autologin` — `initial_session` preserves it |
| Initramfs layout | mkinitcpio presets, `/boot/initramfs-linux-cachyos.img` | Boot Loader Spec, `/boot/<machine-id>/<kernel>/initramfs`; `/etc/mkinitcpio.d/` **empty** |
| Rebuild command | `sudo mkinitcpio -P` | **`sudo limine-mkinitcpio`** — `mkinitcpio -P` builds nothing |
| Secure Boot | not recorded — **check before reusing xps's steps** | **enabled/deployed**, `sbctl`-managed; entries carry BLAKE2B hashes. See [Secure Boot](#secure-boot-and-verified-boot-entries) |
| Fallback initramfs | present | **none** |
| Rollback path | `-fallback` entry | **Snapper snapshot entries** — take one before the `HOOKS` edit; fix `MAX_SNAPSHOT_ENTRIES` first |
| Kernels installed | not recorded | `linux-cachyos` 7.2.2 + `linux-cachyos-lts` 6.18.48 (shared `mkinitcpio.conf` — not a fallback) |
| cmdline operator | `KERNEL_CMDLINE[default]=` | `KERNEL_CMDLINE[default]+=` — **keep the `+=`** |
| Pre-existing cmdline | not recorded (only the post-migration value is) | `cryptdevice=` — must be replaced in the same reboot as the `HOOKS` change |
| Console keymap | — | `/etc/vconsole.conf`: `KEYMAP=br-abnt2` — the PIN is typed blind |
| USB / key placement | not recorded | **must be a direct laptop port, not the dock** — the dock's hub chain enumerates past `token-timeout=1s`. See [When boot ignores the key](#when-boot-ignores-the-key-token-timeout-and-usb-topology) |
| Console-noise audit | stale `99-mouseless-input.rules`, removed | not applicable — only `99-hide-ipu6-raw.rules`, which is **load-bearing** |
| Bootloader | Limine | Limine |
| Greeter | greetd + tuigreet | same — **live and verified**, `Service=greetd` / `Type=wayland`, sddm inactive |
| `niri-session` | **stock** `/usr/bin/niri-session` — tty1 deprecation warning still present; scripted path documented but **not yet applied**, see [Applying it on daisy](#applying-it-on-daisy) | **local wrapper** `/usr/local/bin/niri-session-local`, absolute path in both greetd commands; installed and **confirmed by reboot** on 2026-09-04. See [the wrapper section](#the-deprecation-warning-on-tty1-and-the-local-session-wrapper) |
| FIDO2 keys enrolled | 2 YubiKeys | **2 YubiKeys** — 3 keyslots, 2 `systemd-fido2` tokens, both PIN-required |
| `SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0` | required | **required** — same double-prompt bug, confirmed at `sd-encrypt:29` |
| Secret Service | oo7, TPM2-unsealed | **same** — oo7 0.6.0, 20 items migrated v0 → v1 intact, collection unlocked at start |
| Keyring unlock mechanism | `systemd-creds` + TPM2 | **same** — `ImportCredential=` ships in the vendor unit; `pam_oo7` unused on both |
| Fingerprint reader | not recorded | **Goodix MOC (press)**, `27c6:63bc` — `pam_fprintd_grosshack` in `sudo` + `polkit-1` only, stock `pam_fprintd` in `swaylock`, never boot or greeter |

Everything not listed transfers unchanged.
