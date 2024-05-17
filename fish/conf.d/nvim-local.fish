if test -d ~/.local/nvim/bin
    set -x PATH ~/.local/nvim/bin $PATH
else
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    tar xzf nvim-linux64.tar.gz -C ~/.local
    set -x PATH ~/.local/nvim/bin $PATH
end
