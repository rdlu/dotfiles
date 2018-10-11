set ANACONDA_DIR /opt/anaconda
if test -e $ANACONDA_DIR/bin
  set -gx PATH $PATH $ANACONDA_DIR/bin
  source $ANACONDA_DIR/etc/fish/conf.d/conda.fish
end