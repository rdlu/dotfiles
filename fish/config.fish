for snippet in {$HOME}/.dotfiles/fish/conf.d/*
    source $snippet
end

test -e {$HOME}/.asdf/asdf.fish ; and source {$HOME}/.asdf/asdf.fish

test -e {$HOME}/.dotfiles/fish/variables.fish ; and source {$HOME}/.dotfiles/fish/variables.fish
test -e {$HOME}/.dotfiles/fish/aliases.fish ; and source {$HOME}/.dotfiles/fish/aliases.fish
test -e {$HOME}/.dotfiles/fish/functions.fish ; and source {$HOME}/.dotfiles/fish/functions.fish
test -e {$HOME}/.config/fish/config.local ; and source {$HOME}/.config/fish/config.local

# test $TERM != "screen-256color"; and exec tmux new -A -s mux0 fish

# chips
# if [ -e ~/.config/chips/build.fish ] ; source ~/.config/chips/build.fish ; end

# installing fisher
if not type -q fisher
    curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
    rm ~/.config/fish/fish_plugins
    ln -s ~/.dotfiles/fish/fisher/fish_plugins ~/.config/fish/fish_plugins
end

# starhip.rs
if type -q starship; starship init fish | source; end 