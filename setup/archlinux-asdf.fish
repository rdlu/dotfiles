#! /usr/bin/fish

if type -q asdf
    # node
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    # elixir
    yay -S --needed ncurses base-devel libssh libxslt fop unixodbc
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git

    yay -S --needed unzip
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git

    # ruby
    yay -S --needed base-devel libffi libyaml openssl zlib ruby-build
    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
else
    yay -S --needed asdf-vm-git
end