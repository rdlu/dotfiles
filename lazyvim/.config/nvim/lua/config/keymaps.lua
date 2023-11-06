-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>rw", "*ciw", { desc = "Replace inner word under cursor" })
vim.keymap.set("n", "<leader>rn", "*cgn", { desc = "Replace next word under cursor and jump" })
