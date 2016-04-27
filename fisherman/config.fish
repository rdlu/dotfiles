set PATH  $PATH

set -Ux EDITOR vim
set -Ux VISUAL vim

#NPM
set NPM_PACKAGES $HOME/.npm-packages
set NODE_PATH $NPM_PACKAGES/lib/node_modules $NODE_PATH
set -e MANPATH
set MANPATH $NPM_PACKAGES/share/man (manpath)

set -gx GOPATH ~/Apps/go
set -gx ANDROID_HOME /opt/android-sdk
set -gx BD_OPT 'insensitive'

set -gx PATH $HOME/.local/bin ~/bin $NPM_PACKAGES/bin $PATH ~/Apps/go/bin ~/.fzf

function fish_user_key_bindings
  # ...
  bind \e\e 'thefuck-command-line'  # Bind EscEsc to thefuck
  # or
  bind \cf 'thefuck-command-line'  # Bind Ctrl+F to thefuck
  # ...
end

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

. .config/fish/config.local
