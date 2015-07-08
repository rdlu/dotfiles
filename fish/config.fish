# Path to your oh-my-fish.
set fish_path $HOME/.oh-my-fish

# Path to your custom folder (default path is ~/.oh-my-fish/custom)
set fish_custom $HOME/dotfiles/oh-my-fish

# Load oh-my-fish configuration.
. $fish_path/oh-my-fish.fish

# Custom plugins and themes may be added to ~/.oh-my-fish/custom
# Plugins and themes can be found at https://github.com/oh-my-fish/
Plugin 'xdg'
Plugin 'balias'
Plugin 'theme'
Plugin 'rbenv'
Theme 'cmorrell.com'

#RBENV
#set PATH $HOME/.rbenv/bin $PATH
#set PATH $HOME/.rbenv/shims $PATH
#set PATH $HOME/.rbenv/plugins/ruby-build/bin $PATH
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


# cd aliases
function ..
  cd ..
end
function cd.
  cd ..
end
function cd..
  cd ../..
end
function cd...
  cd ../../..
end
function cd....
  cd ../../../..
end
function cd.....
  cd ../../../../..
end
function cd......
  cd ../../../../../..
end

