# Micro Editor; Linux
test -e /usr/bin/micro; and set -Ux EDITOR micro
# Micro Editor; MacOS
test -e /usr/local/bin/micro; and set -Ux EDITOR micro


#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH

set MANPATH $NPM_PACKAGES/share/man $MANPATH

set -gx BD_OPT insensitive

mkdir -p $HOME/.local/bin $NPM_PACKAGES/bin $HOME/.fzf
set -gx PATH $HOME/.local/bin $HOME/.yarn/bin $HOME/.cargo/bin $NPM_PACKAGES/bin $PATH $HOME/.fzf

set -gx PROJECT_HOME $HOME/Projects

set -gx DOCKER_BUILDKIT 1

# GPG TTY for TMUX
set -lx GPG_TTY (tty)
