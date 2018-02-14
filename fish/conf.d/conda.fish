set ANACONDA_DIR /opt/anaconda
ln -sf /opt/anaconda/bin/conda ~/.bin/conda
set -gx PATH ~/.bin $PATH
source (conda info --root)/etc/fish/conf.d/conda.fish