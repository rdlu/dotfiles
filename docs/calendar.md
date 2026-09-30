# Calendar

Two terminal calendars run side by side on both hosts (daisy and xps), each
synced with Google Calendar:

- **khal + vdirsyncer**: vdirsyncer keeps a local vdir in sync with Google,
  and khal reads it.
- **chroncal**: a Go TUI/CLI with its own SQLite store and built-in Google sync.

`calendar-google` (also `just gcal <subcommand> [app]`) sets both up and keeps
them working. Everything secret is **per host** and never in this repo.

## Install

```sh
just pkg-install calendar   # khal, vdirsyncer, python-aiohttp-oauthlib, libsecret
mise install                # chroncal (github:DouglasdeMoura/chroncal, terminal mise config)
just stow                   # khal + vdirsyncer configs, calendar-google in ~/.local/bin
calendar-google setup       # both apps; or: calendar-google setup vdirsyncer|chroncal
```

## How it fits together

| | khal + vdirsyncer | chroncal |
| --- | --- | --- |
| Talks to | Google CalDAV (`apidata.googleusercontent.com`), scope `auth/calendar` | the same |
| OAuth client | the Secret Service (oo7), fetched by `vdirsyncer/config` | inside chroncal's own credential |
| Token | `~/.local/share/vdirsyncer/google_token` | inside chroncal's own credential |
| Local data | `~/.local/share/calendars/google/<calendar>/*.ics` | `~/.local/share/chroncal/chroncal.db` |
| Background sync | `vdirsyncer.timer` (packaged): `vdirsyncer sync` every 15 min | `chroncal-alarm.timer`: `chroncal service run` every minute (alarms), sync every 15 min |

By default both apps use **one** Google OAuth client per host. `setup` asks for
it once, and `setup` and `rotate-client` let you give chroncal a separate one.

## Create the Google OAuth client (once per host)

In the [Google Cloud Console](https://console.cloud.google.com/), in any project
of yours (the Google Drive one works too):

1. **APIs & Services → Library**: enable the **Google Calendar API** *and* the
   **CalDAV API**. Both apps use CalDAV, and until that API is enabled Google
   answers `403 accessNotConfigured`.
2. **OAuth consent screen** (Google Auth Platform): user type **External**. Then,
   under **Audience**, click **Publish app** so the status is **In production**.
3. **Credentials** (Clients) → **Create credentials → OAuth client ID**, with
   application type **Desktop app**, named after the host (`xps calendar`,
   `daisy calendar`). Keep the client ID and secret for `calendar-google setup`.

!!! warning "Publish the app. Don't leave it in Testing"
    While the consent screen is in **Testing**, Google expires refresh tokens
    after **7 days**, and both calendars stop syncing every week. Published but
    *unverified* is fine for personal use. At consent, Google shows "Google
    hasn't verified this app": click **Advanced → Go to … (unsafe)**, and tick
    the calendar access box if Google shows one.

With one client per host, you can revoke or rotate one host without touching
the other.

## Subcommands

`app` is `vdirsyncer` or `chroncal`. Without it, a command covers both apps.

| Command | When |
| --- | --- |
| `calendar-google setup [app]` | First time on a host. Checks the tools and asks every question up front: the OAuth client (only if the keyring has none), whether chroncal should share it, and the Google account email for chroncal. Stores the client in oo7, then opens the browser once per app. vdirsyncer then runs discover, the first sync and metasync, and enables `vdirsyncer.timer`. chroncal runs `account add` (which imports every calendar and syncs) and `service install`. Idempotent: on a finished host it only checks, and it reinstalls chroncal's service if the unit points at a binary that no longer exists. |
| `calendar-google status [app]` | Anytime. Read-only: tools, keyring entries (yes/no), token file, a live token check for vdirsyncer, timers enabled + active + last run, calendars and events on disk, `khal list`, the chroncal account, where its credential lives, whether it shares vdirsyncer's client, what the last background sync recorded, and the service binary. Exit 1 if anything is wrong. Never prints a secret or token. |
| `calendar-google reauth [app]` | A token expired or was revoked (`status` says `invalid_grant`). Re-consent in the browser. |
| `calendar-google rotate-client [app]` | New OAuth client (the old one leaked, or you're cleaning up). Asks for the new ID + secret (optionally a separate one for chroncal), re-consents (tokens are bound to their client), then prints the old client ID(s) to delete in the console. It warns instead if the other app still uses the old client. |

What each check touches:

- **vdirsyncer live check** (`status`, and after every consent): a CalDAV
  discovery with a throwaway config, a throwaway status dir and a *copy* of the
  token. A token refresh can't rewrite the real token, and nothing under
  `~/.local/share` changes. It only runs when the token file holds a refresh
  token, with no display and a no-op `$BROWSER`, so it can never start a
  sign-in.
- **chroncal in `status`** makes no network call. It reads `chroncal sync status`,
  which is what the background sync recorded (an error, or a last sync more
  than an hour ago, counts as unhealthy). `setup`, `reauth` and `rotate-client`
  check chroncal live with `chroncal account calendars list`. Like any chroncal
  run, that may refresh the access token and update calendar names and colours
  in its database.
- `status` never creates chroncal's database. On a host where chroncal never
  ran, it just reports that.

### Failure and Ctrl-C

`reauth` and `rotate-client` back up what they replace, and put it back if the
consent or the check afterwards fails, or if you press Ctrl-C:

| App | What is backed up | Where |
| --- | --- | --- |
| vdirsyncer | token file (moved aside, which also forces a fresh sign-in) | `google_token.pre-change` |
| vdirsyncer | OAuth client (`rotate-client`) | keyring `service google-caldav key client_id_prev` / `client_secret_prev` |
| chroncal | its credential (client + tokens) | `<credential file>.pre-change`, or keyring `service calendar-google key chroncal_credential_backup` |

Each app's timer is stopped while its credentials change, so a background sync
without a token can't start its own sign-in, and it is started again at the end.
With two apps, a failure in the second one keeps the first on its new token or
client and says so. Don't delete the old client in that case.

If the script itself is killed (crash, power loss), backups can be left behind.
`status` flags them, and the next `setup`, `reauth` or `rotate-client` resolves
them first: if the current state works, it discards the backup; if not, it
restores the backup. It also restarts a timer the interrupted run left stopped.

## What lives where (per host)

| Thing | Where |
| --- | --- |
| vdirsyncer's OAuth client | oo7: `secret-tool lookup service google-caldav key client_id` (and `key client_secret`) |
| vdirsyncer token | `~/.local/share/vdirsyncer/google_token` (refresh token, 0600) |
| vdirsyncer state | `~/.local/share/vdirsyncer/status/`, and the calendars in `~/.local/share/calendars/google/` |
| chroncal database | `~/.local/share/chroncal/chroncal.db` (`$CHRONCAL_DB` or a `db` key in its config override it) |
| chroncal credential, if its keyring works | Secret Service item `service chroncal`, `username db_<namespace>_account_<id>`, holding JSON with the client ID + secret and the tokens |
| chroncal credential, plaintext fallback | `~/.config/chroncal/credentials/db_<namespace>/account_<id>.json` (0600) |
| chroncal config (local only, not stowed) | `~/.config/chroncal/config.toml`. On daisy it sets `[security] allow_plaintext = true` |
| chroncal service | `~/.config/systemd/user/chroncal-alarm.{service,timer}`, written by `chroncal service install` (not stowed) |

`<namespace>` is chroncal's per-database credential scope: the database UUID
plus a hash of the database file's inode. A copied database gets a new one, and
therefore no credential. Copying `chroncal.db` to another host doesn't carry the
account over. Set it up there with `calendar-google setup chroncal`.

### chroncal and oo7: the plaintext fallback

chroncal stores credentials through go-keyring. go-keyring looks for the
Secret Service collection `/org/freedesktop/secrets/collection/login`. oo7 names
it `Login`, so go-keyring falls back to unlocking the alias
`/org/freedesktop/secrets/aliases/default`. oo7 (0.6) answers that `Unlock` with
an empty list, which go-keyring treats as a failure. chroncal then has no
keyring, and it refuses to store a new secret with *"no secure credential store
is available"*. It refuses before it prompts or opens the browser.

The fallback is opt-in: chroncal writes the credential (client secret + refresh
token, in cleartext) to a 0600 file under `~/.config/chroncal/credentials/`,
outside the repo. There are two ways to opt in:

- **daisy**: the local-only `~/.config/chroncal/config.toml` sets
  `security.allow_plaintext`, so chroncal uses the file without asking.
- **xps / anywhere else**: `calendar-google setup` sees the refusal, explains
  it, and asks. On **y**, it re-runs `account add` with `--allow-plaintext`.
  After that, chroncal keeps rewriting that file (token refresh, reauth)
  without the opt-in.

`status` shows which store holds the credential. Keep `~/.config/chroncal` out
of anything that syncs or backs up to places you don't trust. vdirsyncer is not
affected: libsecret resolves the alias itself.

## Troubleshooting

- **Everything stops after a week**: the consent screen is still in Testing.
  Publish it, then run `calendar-google reauth`.
- **`403 accessNotConfigured`**: enable the **CalDAV API** in the client's project.
- **`invalid_client`**: the client was deleted or its secret changed. Run
  `calendar-google rotate-client`.
- **`invalid_grant`**: the token was revoked or expired. Run `calendar-google reauth`.
- **chroncal service points at a missing binary** (after `mise upgrade`
  prunes the version it was installed from): run `calendar-google setup chroncal`.
- **A new Google calendar**: `vdirsyncer discover` picks it up (the pair has
  `implicit = "create"`, so it doesn't ask y/N). For chroncal, run
  `chroncal account calendars add Google --all`.

## Files

| Thing | Path |
| --- | --- |
| Script | `~/.local/bin/calendar-google` (`scripts/dot-local/bin/`) |
| vdirsyncer config | `terminal/dot-config/vdirsyncer/config` |
| khal config | `terminal/dot-config/khal/config` |
| chroncal (mise) | `terminal/dot-config/mise/config.toml` |
| Launchers | `home/dot-local/share/applications/{khal,dev.rdlu.Khal,dev.rdlu.Chroncal}.desktop` |
| Packages | `calendar` category in `setup/packages.yaml` |
| Recipe | `just gcal <subcommand> [app]` |
