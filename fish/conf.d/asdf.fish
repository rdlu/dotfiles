# Initialize ASDF

set COMPLETION_SCRIPT ~/.asdf/completions/asdf.fish

# Test Pacman / AUR version
if [ -e  /opt/asdf-vm/asdf.fish ]
    source /opt/asdf-vm/asdf.fish
    set COMPLETION_SCRIPT /opt/asdf-vm/completions/asdf.fish
end

# MacOS / Homebrew
if [ -e  /usr/local/opt/asdf/asdf.fish ]
    source /usr/local/opt/asdf/asdf.fish
    set COMPLETION_SCRIPT /usr/local/opt/asdf/asdf.fish
end

# Git version
test -e {$HOME}/.asdf/asdf.fish ; and source {$HOME}/.asdf/asdf.fish

if not test -e ~/.config/fish/completions/asdf.fish
    mkdir -p ~/.config/fish/completions; and ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
end
