# Initialize ASDF

# Test Pacman / AUR version
if [ -e  /opt/asdf-vm/asdf.fish ] ; source /opt/asdf-vm/asdf.fish ; end

# MacOS / Homebrew
if [ -e  /usr/local/opt/asdf/asdf.fish ] ; source /usr/local/opt/asdf/asdf.fish ; end

# Git version
test -e {$HOME}/.asdf/asdf.fish ; and source {$HOME}/.asdf/asdf.fish