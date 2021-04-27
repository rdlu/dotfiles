set isWSL2 (uname -a | grep WSL2)

if type -q gpg && test (uname) != Darwin
    if test -n $isWSL2 && type -q socat && type -q nohup
        pkill gpg-agent

        ## SSH via WSL2
        set -x SSH_AUTH_SOCK $HOME/.ssh/agent.sock
        ss -a | grep -q $SSH_AUTH_SOCK
        if [ $status != 0 ]
            rm -f $SSH_AUTH_SOCK
            setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:$HOME/.ssh/wsl2-ssh-pageant.exe >/dev/null 2>&1 &
        end

        ## GPG via WSL2
        set -x GPG_AGENT_SOCK $HOME/.gnupg/S.gpg-agent
        ss -a | grep -q $GPG_AGENT_SOCK
        if [ $status != 0 ]
            rm -rf $GPG_AGENT_SOCK
            setsid nohup socat UNIX-LISTEN:$GPG_AGENT_SOCK,fork EXEC:"$HOME/.ssh/wsl2-ssh-pageant.exe --gpg S.gpg-agent" >/dev/null 2>&1 &
        end
    else
        set -e GPG_TTY
        set -U -x GPG_TTY (tty)
        set -e SSH_AUTH_SOCK
        set -U -x SSH_AUTH_SOCK /run/user/(id -u)/gnupg/S.gpg-agent.ssh
        gpg-connect-agent updatestartuptty /bye > /dev/null
    end
end