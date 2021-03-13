set RBENV_DIR $HOME/.rbenv
if test -e $RBENV_DIR/bin
  set -gx PATH $PATH $RBENV/bin
end


which rbenv > /dev/null
if test $status -eq 0
    status --is-interactive; and source (rbenv init -|psub)
end
