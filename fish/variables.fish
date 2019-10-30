set PATH  $PATH

#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH

set -e MANPATH
set MANPATH $NPM_PACKAGES/share/man (manpath)

set -gx GOPATH ~/Apps/go
set -gx BD_OPT 'insensitive'

mkdir -p $HOME/.local/bin $NPM_PACKAGES/bin $PATH $HOME/.fzf
set -gx PATH $HOME/.local/bin $HOME/.yarn/bin $NPM_PACKAGES/bin $PATH $HOME/.fzf

# Python PIP and VENV
set -gx PYTHONPATH (python -c "import site, os; print(os.path.join(site.USER_BASE, 'lib', 'python', 'site-packages'))"):$PYTHONPATH
set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
