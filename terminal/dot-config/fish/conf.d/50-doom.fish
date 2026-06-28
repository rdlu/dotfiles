# Doom Emacs CLI on PATH (doom sync / doom doctor / doom upgrade).
# Framework lives at ~/.config/emacs (a git clone, not stowed); config is the
# `doom` stow package -> ~/.config/doom.
if test -d $HOME/.config/emacs/bin
    fish_add_path -g $HOME/.config/emacs/bin
end
