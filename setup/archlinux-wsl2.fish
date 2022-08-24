#! /usr/bin/fish

ln -s ~/.dotfiles/local/bin/win-gpg-agent-relay.sh ~/.local/bin/win-gpg-agent-relay.sh

fancy_print_title "GPG Tools on windows side"
fancy_print_line "Install scoop.sh"

fancy_print_line "scoop install gnupg"
echo "For an older version 2.2.27"
echo "scoop install https://raw.githubusercontent.com/ScoopInstaller/Main/378b6266cbe31a46709bc1068a0232c1429c79bb/bucket/gnupg.json"
fancy_print_line "scoop install win-gpg-agent"
echo "Win + R, then shell:startup"
echo "create the agent-gui shortcut pointing to C:\Users\rodri\scoop\apps\win-gpg-agent\current\agent-gui.exe"
echo "also configure agent-gui.conf"
