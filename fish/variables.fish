set PATH  $PATH

#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH

set -e MANPATH
set MANPATH $NPM_PACKAGES/share/man (manpath)

set -gx GOPATH ~/Apps/go
set -gx BD_OPT 'insensitive'

set -gx PATH $HOME/.local/bin $NPM_PACKAGES/bin $PATH $HOME/.fzf