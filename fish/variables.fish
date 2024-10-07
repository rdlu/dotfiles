# Micro Editor; Linux
test -e /usr/bin/micro; and set -Ux EDITOR micro
# Micro Editor; MacOS
test -e /usr/local/bin/micro; and set -Ux EDITOR micro

set -gx BD_OPT insensitive

mkdir -p $HOME/.local/bin $HOME/.fzf
set -gx PATH $HOME/.local/bin $HOME/.yarn/bin $HOME/.cargo/bin $HOME/.local/npm/bin /usr/lib64 $PATH $HOME/.fzf

set -gx PROJECT_HOME $HOME/Projects

set -gx DOCKER_BUILDKIT 1

# GPG TTY for TMUX
set -lx GPG_TTY (tty)

set -gx SSH_ASKPASS_REQUIRE prefer
set -gx SSH_ASKPASS /usr/bin/systemd-ask-password
