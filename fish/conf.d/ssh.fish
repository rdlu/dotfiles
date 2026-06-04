# Set up a persistent SSH agent socket
set -gx ssh_agent_file "$HOME/.ssh/agent.env"

function __start_agent
    set ssh_agent_file "$HOME/.ssh/agent.env"
    echo "Starting new SSH agent..."
    ssh-agent -c | sed 's/^echo/#echo/' >$ssh_agent_file
    chmod 600 $ssh_agent_file
    source $ssh_agent_file
end

# Check if the agent file exists
if test -f $ssh_agent_file
    # Source the agent file to load existing environment
    source $ssh_agent_file >/dev/null

    # Check if the agent is still running
    if not ps -p $SSH_AGENT_PID >/dev/null
        # Agent not running, start a new one
        __start_agent
    end
else
    # No agent file exists, start a new agent
    __start_agent
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
