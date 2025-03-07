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
