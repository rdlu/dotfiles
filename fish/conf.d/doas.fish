if type -q doas
    # abbr -s sudo 'doas'
    # abbr -s sudoedit 'doas rnano'

    complete -c doas -f -a '(__fish_complete_command)'
    complete -c doas -r -n __fish_use_subcommand -n '__fish_complete_suffix conf' -s C -d 'Parse and check config file only; supply a command for matching'
    complete -c doas -n __fish_use_subcommand -s L -d 'Clear any persisted authentications from previous invocations, then immediately exit'
    complete -c doas -n __fish_use_subcommand -s n -d "Non-interactive mode, fails if matching rule doesn't have nopass option"
    complete -c doas -n __fish_use_subcommand -s s -d 'Execute the shell from SHELL or /etc/passwd'
    complete -c doas -x -n __fish_use_subcommand -s u -d 'Execute the command as user (default: root)' -a '(__fish_complete_users)'
end
