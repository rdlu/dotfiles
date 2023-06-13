# Micro Editor; Linux
test -e /usr/bin/micro; and set -Ux EDITOR micro
# Micro Editor; MacOS
test -e /usr/local/bin/micro; and set -Ux EDITOR micro


#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH

set MANPATH $NPM_PACKAGES/share/man $MANPATH

set -gx BD_OPT insensitive

mkdir -p $HOME/.local/bin $NPM_PACKAGES/bin $PATH $HOME/.fzf
set -gx PATH $HOME/.local/bin $HOME/.yarn/bin $HOME/.cargo/bin $NPM_PACKAGES/bin $PATH $HOME/.fzf

# Python PIP and VENV
set -gx PYTHONPATH (python -c "import site, os; print(os.path.join(site.USER_BASE, 'lib', 'python', 'site-packages'))"):$PYTHONPATH
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1

set -gx PROJECT_HOME $HOME/Projects

set -gx DOCKER_BUILDKIT 1


# Go Lang PATH
if test -d $HOME/.local/go
    set -gx GOPATH $HOME/.local/go
    set -gx PATH $PATH $HOME/.local/go/bin
else
    mkdir -p $HOME/.local/go
end

# Elixir / Erl
set -gx ERL_AFLAGS '-kernel shell_history enabled'
set -gx KERL_CONFIGURE_OPTIONS "--enable-wx --with-wx --enable-webview --with-wx-config=/usr/bin/wx-config-3.2"
set -gx KERL_BUILD_DOCS yes

# GPG TTY for TMUX
set -lx GPG_TTY (tty)
