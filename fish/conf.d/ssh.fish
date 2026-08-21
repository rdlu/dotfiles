# ssh-agent runs as a systemd user service (ssh-agent.service) on a fixed
# socket, so every shell shares one agent. Shells started from the graphical
# session inherit SSH_AUTH_SOCK from environment.d; this covers the ones that
# don't (tty logins, su). Inbound ssh sessions keep their forwarded agent.
if not set -q SSH_CONNECTION; and set -q XDG_RUNTIME_DIR
    if test -S $XDG_RUNTIME_DIR/ssh-agent.socket
        set -gx SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
    end
end

# Wrap ssh to automatically toggle tmux into "OFF" mode for nested tmux
# sessions on the remote. Mirrors the F12 binding in ~/.tmux.conf so
# that the local prefix is disabled while the ssh session is alive and
# restored when it exits (for any reason).
function ssh --wraps=ssh --description 'ssh wrapper that unlocks the local tmux prefix for nested sessions'
    if set -q TMUX
        tmux set prefix None \; \
            set key-table off \; \
            set status-style "fg=colour245,bg=colour52" \; \
            set window-status-current-style "fg=colour232,bold,bg=colour160" \; \
            set window-status-current-format " #I: #W [REMOTE] " \; \
            refresh-client -S
    end

    command ssh $argv
    set -l ssh_status $status

    if set -q TMUX
        tmux set -u prefix \; \
            set -u key-table \; \
            set -u status-style \; \
            set -u window-status-current-style \; \
            set -u window-status-current-format \; \
            refresh-client -S
    end

    return $ssh_status
end
