#! /usr/bin/fish
rtx completion fish > ~/.config/fish/completions/rtx.fish

rtx plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
sudo dnf install -y git-core zlib zlib-devel gcc-c++ patch readline \
    readline-devel libyaml libyaml-devel libffi-devel openssl-devel \
    make bzip2 autoconf automake libtool bison curl sqlite-devel
rtx install ruby

sudo dnf install -y erlang elixir erlang-rebar3 erlang-erl_interface
sudo dnf install -y autoconf openssl-devel ncurses-devel wxGTK3-devel \
    wxBase3 libiodbc unixODBC-devel erlang-odbc libxslt fop wxGTK wxGTK-devel \
    wxGTK-gl wxGTK-media java-11-openjdk-devel
sudo yum groupinstall -y 'Development Tools' 'C Development Tools and Libraries'
rtx plugin add erlang https://github.com/asdf-vm/asdf-erlang.git
set -lx KERL_CONFIGURE_OPTIONS "--cache-file=/dev/null --enable-wx --with-wx --enable-webview --with-wx-config=$(which wx-config-3.2)
    --enable-dynamic-ssl-lib \                     
    --enable-kernel-poll \                         
    --enable-shared-zlib \                         
    --enable-smp-support \                         
    --enable-threads "
rtx install erlang

rtx plugin add elixir https://github.com/asdf-vm/asdf-elixir.git