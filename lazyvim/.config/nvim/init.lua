-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.cmd([[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
]])
