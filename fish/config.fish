for snippet in {$HOME}/.dotfiles/fish/conf.d/*
    source $snippet
end

test -e {$HOME}/.dotfiles/fish/variables.fish ; and source {$HOME}/.dotfiles/fish/variables.fish
test -e {$HOME}/.dotfiles/fish/aliases.fish ; and source {$HOME}/.dotfiles/fish/aliases.fish
test -e {$HOME}/.config/fish/config.local ; and source {$HOME}/.config/fish/config.local

# test $TERM != "screen-256color"; and exec tmux new -A -s mux0 fish