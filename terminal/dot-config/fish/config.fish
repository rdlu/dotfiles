if not status --is-interactive
    exit
end

for snippet in {$HOME}/.dotfiles/fish/conf.d/*
    source $snippet
end

test -e {$HOME}/.dotfiles/fish/variables.fish; and source {$HOME}/.dotfiles/fish/variables.fish
test -e {$HOME}/.dotfiles/fish/aliases.fish; and source {$HOME}/.dotfiles/fish/aliases.fish
test -e {$HOME}/.dotfiles/fish/functions.fish; and source {$HOME}/.dotfiles/fish/functions.fish
test -e {$HOME}/.config/fish/config.local; and source {$HOME}/.config/fish/config.local
test -e {$HOME}/.config/fish/config.local.fish; and source {$HOME}/.config/fish/config.local.fish

# test $TERM != "screen-256color"; and exec tmux new -A -s mux0 fish

# installing fisher
if not type -q fisher
    echo 'Fisher is not installed, package management not available'
end

if type -q mise
    mise activate fish | source
end

# starhip.rs
if type -q starship
    starship init fish | source
end

# Initialize atuin
if type -q atuin
    atuin init fish --disable-up-arrow | source
end

if set -q START_TMUX; and not set -q TMUX; and status is-interactive; and not set -q INSIDE_EDITOR
    tmux new -A -s mux0 fish
end
