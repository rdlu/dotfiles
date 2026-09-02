# LUKS FIDO2 unlock + greetd login

Migration guide: unlock the root LUKS volume with a FIDO2 security key
instead of typing the disk passphrase, and replace the stock display
manager with [greetd](https://sr.ht/~kennylevinsen/greetd/) + `tuigreet`.

Completed on **daisy** (AMD). Being applied to **xps** (Intel, Dell XPS
9320, i7-1260P). Both run CachyOS with
[Limine](https://limine-bootloader.org/) as the bootloader and niri as
the compositor — but they diverge in enough places that every command
below is labelled per machine where it differs. The divergences are not
cosmetic: **the initramfs rebuild command, the display manager, and the
rollback path are all different on xps.**

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
  working on daisy.
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
    - **xps: kept.** The hook stays, moved from its busybox position to
      directly after `systemd`, and `splash` stays on the cmdline.

    This was previously an open question. It is now settled per machine;
    the reasoning below is retained because it is what you need if the
    splash misbehaves on xps.

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

!!! warning "xps is affected too — this is not optional there"

    It is worth confirming rather than assuming, and xps confirms:
    `/usr/lib/initcpio/install/sd-encrypt:29` copies
    `libcryptsetup-token-systemd-fido2.so` into the initramfs. The plugin
    will be present, so the double prompt will happen. Treat the flag as
    a required part of the cmdline change, not a fix to apply if the
    symptom shows up.

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

Independent of the LUKS work, and the half to do **first** — see
[Do it in two reboots](#do-it-in-two-reboots-greetd-first).

Both packages are declared in the manifest under `niri-wm`
(`setup/packages.yaml:95-96`). On xps, `greetd` 0.10.3 is already
installed; only `greetd-tuigreet` is missing (0.11.1-2.1, in
`cachyos-extra-v3` — a binary package, no AUR build):

```sh
paru -S --needed greetd-tuigreet    # narrow: just the missing piece
# or: mise run pkg-install niri-wm  # installs the WHOLE category, oo7 included
```

Write `/etc/greetd/config.toml`. daisy's working config — xps's is still
the stock default (`agreety --cmd /bin/sh`, user `greeter`, vt 1), i.e.
never configured, so this replaces it wholesale:

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

The `greeter` system user already exists on xps (uid 959), and
`/usr/bin/niri-session` is present, as are `gnome.desktop` and
`niri.desktop` under `/usr/share/wayland-sessions/`.

!!! note "`initial_session` is autologin — and xps already autologins"

    That block logs `rdlu` straight into niri on the **first** boot of
    the session, skipping the greeter entirely — convenient on a
    single-user laptop with an encrypted disk, since the LUKS unlock is
    already the real authentication gate. Drop the block if you want the
    greeter every time.

    On xps this **preserves existing behaviour** rather than changing it:
    the live session reports `Service=sddm-autologin`, so sddm is already
    logging the user straight in. Keeping `initial_session` means the
    swap is invisible on a normal boot, and the greeter only shows up
    when you actually log out.

This file is **not tracked in this repo**: it is root-owned, and the
stow tree only targets `$HOME`. It has to be written by hand on each
machine — hence its inclusion verbatim above.

### Swap the display manager

!!! danger "It is sddm on xps, not gdm"

    daisy came from **gdm**. xps runs **sddm**:
    `display-manager.service` resolves to
    `/usr/lib/systemd/system/sddm.service`, `sddm` is enabled, `gdm` is
    installed but already disabled, and `lightdm` is not installed at
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

## Rollback

Recovery paths, cheapest first.

**FIDO2 unlock fails, or the key is lost/forgotten.** Not really a
failure mode: boot without the key and the passphrase prompt appears
immediately, exactly as it did before enrollment. To drop the FIDO2 slot
afterwards:

```sh
sudo systemd-cryptenroll --wipe-slot=fido2 "$LUKS_PART"
```

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

**Nothing works.** Rescue media, unlock with the passphrase,
`arch-chroot`, `systemctl disable greetd`, revert the cmdline in
`/etc/default/limine`, then `limine-update` + `mkinitcpio -P` (daisy) or
`limine-mkinitcpio` (xps).

## daisy vs xps

Every row here is a verified difference, not a guess.

| Item | daisy (AMD) | xps (Intel, XPS 9320) |
| ---- | ----------- | --------------------- |
| LUKS partition | `nvme1n1p2` | `nvme0n1p2`, UUID `be1ed90f-6dec-438d-95c3-fdc12d1a26e5` |
| Second disk | `nvme0n1` = Windows/NTFS | **none** — single NVMe, so the numbering shifts |
| Microcode | `amd-ucode` | `intel-ucode` (installed; `microcode` hook already in `HOOKS`) |
| Plymouth | installed, hook **omitted** | **kept** — hook moved after `systemd`, `splash` retained. See [Plymouth](#plymouth) |
| Display manager | gdm → greetd | **sddm** → greetd (gdm present but already disabled) |
| Autologin before the swap | gdm, no autologin | `sddm-autologin` — `initial_session` preserves it |
| Initramfs layout | mkinitcpio presets, `/boot/initramfs-linux-cachyos.img` | Boot Loader Spec, `/boot/<machine-id>/<kernel>/initramfs`; `/etc/mkinitcpio.d/` **empty** |
| Rebuild command | `sudo mkinitcpio -P` | **`sudo limine-mkinitcpio`** — `mkinitcpio -P` builds nothing |
| Secure Boot | not in use | **enabled/deployed**, `sbctl`-managed; entries carry BLAKE2B hashes. See [Secure Boot](#secure-boot-and-verified-boot-entries) |
| Fallback initramfs | present | **none** |
| Rollback path | `-fallback` entry | **Snapper snapshot entries** — take one before the `HOOKS` edit; fix `MAX_SNAPSHOT_ENTRIES` first |
| Kernels installed | one | `linux-cachyos` 7.2.2 + `linux-cachyos-lts` 6.18.48 (shared `mkinitcpio.conf` — not a fallback) |
| cmdline operator | `KERNEL_CMDLINE[default]=` | `KERNEL_CMDLINE[default]+=` — **keep the `+=`** |
| Pre-existing cmdline | already `rd.luks.name=` | `cryptdevice=` — must be replaced in the same reboot as the `HOOKS` change |
| Console keymap | — | `/etc/vconsole.conf`: `KEYMAP=br-abnt2` — the PIN is typed blind |
| Console-noise audit | stale `99-mouseless-input.rules`, removed | not applicable — only `99-hide-ipu6-raw.rules`, which is **load-bearing** |
| Bootloader | Limine | Limine |
| Greeter | greetd + tuigreet | same (`greetd` installed; `greetd-tuigreet` to add) |
| `SYSTEMD_CRYPTSETUP_USE_TOKEN_MODULE=0` | required | **required** — same double-prompt bug, confirmed at `sd-encrypt:29` |

Everything not listed transfers unchanged.
