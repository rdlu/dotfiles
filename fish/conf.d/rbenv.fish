set RBENV_DIR $HOME/.rbenv
if test -e $RBENV_DIR/bin
  set -gx PATH $PATH $RBENV/bin
end


if type -q rbenv; and status --is-interactive;
   source (rbenv init -|psub)
end
