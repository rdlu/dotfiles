set isWSL2 (uname -a | grep WSL2)

if type -q gpg && test (uname) != Darwin
    if not test -z $isWSL2 && type -q socat && type -q setsid
        # echo "Its WSL2 and socat and setsid"
        set -U -x SSH_AUTH_SOCK $HOME/.gnupg/S.gpg-agent.ssh
        set -U -x GPG_AGENT_SOCK $HOME/.gnupg/S.gpg-agent
        set -U -x GPG_AGENT_SOCK_EXTRA $HOME/.gnupg/S.gpg-agent.extra
        if not ps ax | grep -q '[w]in-gpg-agent-relay'
            echo "Starting Win-GPG-Agent Relay"
            setsid ~/.dotfiles/gnupg/win-gpg-agent-relay.sh foreground 2>/tmp/win-gpg-agent-error.log >/tmp/win-gpg-agent-start.log </dev/null &
        end
    else
        set -e SSH_AUTH_SOCK
        set -U -x SSH_AUTH_SOCK /run/user/(id -u)/gnupg/S.gpg-agent.ssh
        set -e GPG_TTY
        set -gx GPG_TTY (tty)
        gpg-connect-agent updatestartuptty /bye >/dev/null
    end
end

# Ensure correct tty for tmux if using pinentry-curses
alias ssh "GPG_TTY=(tty) gpg-connect-agent updatestartuptty /bye > /dev/null && env ssh"

