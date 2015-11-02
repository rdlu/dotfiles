# Path to your oh-my-fish.
set -g OMF_PATH $HOME/.local/share/omf

# Path to your oh-my-fish configuration.
set -g OMF_CONFIG $HOME/.config/omf

### Configuration required to load oh-my-fish ###
# Note: Only add configurations that are required to be set before oh-my-fish is loaded.
# For common configurations, we advise you to add them to your $OMF_CONFIG/init.fish file or
# to create a custom plugin instead.

# Load oh-my-fish configuration.
source $OMF_PATH/init.fish


#RBENV
#set PATH $HOME/.rbenv/bin $PATH
#set PATH $HOME/.rbenv/shims $PATH
#set PATH $HOME/.rbenv/plugins/ruby-build/bin $PATH
rbenv rehash >/dev/null ^&1

set PATH $HOME/.local/bin $PATH

set -Ux EDITOR vim
set -Ux VISUAL vim

#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH
set PATH $NPM_PACKAGES/bin $PATH
set -e MANPATH
# delete if you already modified MANPATH elsewhere in your config
set MANPATH $NPM_PACKAGES/share/man (manpath)

#set fish_function_path $fish_function_path "/home/rodrigo/.local/lib/python2.7/site-packages/powerline/bindings/fish"
#powerline-setup

#abbreviations
abbr -a gps git push
abbr -a gpl git pull
abbr -a gc git commit -a
abbr -a tf tail -f
abbr -a lsah ls -lah


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

function -e fish_preexec _run_fasd
  fasd --proc (fasd --sanitize "$argv") > "/dev/null" 2>&1
  end

 function j
  cd (fasd -d -e 'printf %s' "$argv")
 end

 set PATH ~/bin $PATH ~/.fzf

. .config/fish/config.local
