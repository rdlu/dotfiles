set RBENV_DIR $HOME/.rbenv
if test -e $RBENV_DIR/bin
    set -gx PATH $PATH $RBENV/bin
end


if type -q rbenv; and status --is-interactive
    source (rbenv init -|psub)
end

# Custom openssl1.1 for older Ruby libs and tools using ancient ssl
# sudo dnf install openssl1.1-devel
# set -lx RUBY_CONFIGURE_OPTS '--with-openssl-dir=/usr/include/openssl11 --with-openssl-lib=/usr/lib64/openssl11 --with-openssl-include=/usr/include/openssl11'
