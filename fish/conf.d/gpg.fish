set -e GPG_TTY
set -U -x GPG_TTY (tty)
set -e SSH_AUTH_SOCK
set -U -x SSH_AUTH_SOCK /run/user/(id -u)/gnupg/S.gpg-agent.ssh
gpg-connect-agent updatestartuptty /bye > /dev/null