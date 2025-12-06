-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.cmd([[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
]])

vim.lsp.config("expert", {
  cmd = { "expert" },
  root_markers = { "mix.exs", ".git" },
  filetypes = { "elixir", "eelixir", "heex" },
})

vim.lsp.enable("expert")
