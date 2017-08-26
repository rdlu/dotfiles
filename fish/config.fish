set PATH  $PATH

#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH
set -e MANPATH
set MANPATH $NPM_PACKAGES/share/man (manpath)

set -gx GOPATH ~/Apps/go
set -gx BD_OPT 'insensitive'

set -gx PATH $HOME/.local/bin $NPM_PACKAGES/bin $PATH $HOME/.fzf

function fish_user_key_bindings
  # ...
  bind \e\e 'fuck'  # Bind EscEsc to thefuck
  # or
  bind \cf 'fuck'  # Bind Ctrl+F to thefuck
  # ...
end

#abbreviations
abbr -a gps git push
abbr -a gpl git pull
abbr -a gc git commit -a
abbr -a tf tail -f
abbr -a lsah ls -lah


thefuck --alias | source

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

 function j
  cd (fasd -d -e 'printf %s' "$argv")
 end

test -e {$HOME}/.config/fish/config.local ; and source {$HOME}/.config/fish/config.local
