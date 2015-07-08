#RBENV
set PATH $HOME/.rbenv/bin $PATH
set PATH $HOME/.rbenv/shims $PATH
set PATH $HOME/.rbenv/plugins/ruby-build/bin $PATH
rbenv rehash >/dev/null ^&1

set PATH $HOME/.local/bin $PATH

#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH
set PATH $NPM_PACKAGES/bin $PATH
set -e MANPATH 
# delete if you already modified MANPATH elsewhere in your config
set MANPATH $NPM_PACKAGES/share/man (manpath)

#set fish_function_path $fish_function_path "/home/rodrigo/.local/lib/python2.7/site-packages/powerline/bindings/fish"
#powerline-setup
