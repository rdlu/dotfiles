#! /usr/bin/fish
cd
yay -S --needed keybase kbfs
keybase pgp export --secret | gpg --allow-secret-key-import --import
keybase pgp pull-private --all
ls ~/.gnupg/private-keys-v1.d/ | sed s/.key// >> ~/.gnupg/sshcontrol
set_color green; echo "Keys loaded for SSH:"
set_color cyan; ssh-add -L
