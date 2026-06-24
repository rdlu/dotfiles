# 📤 How to send me files

Two easy ways — pick whichever suits you. (Heads-up: ping me first so I can
switch on receiving, especially if we're not on the same home network.)

---

## Option 1 — LocalSend (easiest, any phone or computer)
1. **Install LocalSend** — free & open-source: <https://localsend.org>
   (Android, iPhone, Windows, macOS, Linux).
2. **Get on the same Wi-Fi** as me.
3. Open LocalSend, **pick your file(s)**, select my device (shows up as **`@HOST@`**),
   and send. I'll get a prompt to accept.

No accounts, no cloud, no size limits — it goes straight over the local network.

## Option 2 — rsync over SSH (for Linux/Mac terminal folks)
Drops files straight into my inbox folder. One-time setup:

1. **Send me your SSH public key.** On your machine:
   ```
   cat ~/.ssh/id_ed25519.pub          # no key yet? run: ssh-keygen -t ed25519
   ```
   Copy the output and send it to me.
2. I authorize it and tell you when receiving is open.
3. **Send your files:**
   ```
   rsync -av ./your-folder/ @HOST@:        # I'll give you my IP (@IP@) if the name won't resolve
   ```

Your key can *only* upload into my inbox — no shell, nothing else on my machine.

---
_Questions? Just ask. LocalSend (Option 1) is the no-fuss choice for one-off files._
