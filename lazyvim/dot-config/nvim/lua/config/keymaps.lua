-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true

vim.keymap.set("n", "<leader>rw", "*ciw", { desc = "Replace inner word under cursor" })
vim.keymap.set("n", "<leader>rn", "*cgn", { desc = "Replace next word under cursor and jump" })
vim.keymap.set("n", "<leader>ri", ":%s/<c-r><c-w>/<c-r><c-w>/gc<c-f>$F/i", { desc = "Replace test" })

-- delete to null register
vim.keymap.set({ "n", "v" }, "d", '"xd', { noremap = true, silent = true, desc = "Delete" })
vim.keymap.set({ "n", "v" }, "D", '"xD', { noremap = true, silent = true, desc = "Delete" })
vim.keymap.set({ "n", "v" }, "x", '"xx', { noremap = true, silent = true, desc = "Delete" })

vim.keymap.set(
  { "n", "v" },
  "<leader>rw",
  ":MoveWord(1)<CR>'",
  { noremap = true, silent = true, desc = "Swap word forward" }
)
vim.keymap.set(
  { "n", "v" },
  "<leader>rb",
  ":MoveWord(-1)<CR>'",
  { noremap = true, silent = true, desc = "Swap word back" }
)

local buf_utils = require("utils.buffer")
-- buffer management
vim.keymap.set("n", "<leader>bl", function()
  buf_utils.move(vim.v.count > 0 and vim.v.count or 1)
end, { desc = "Move buffer tab right" })
vim.keymap.set("n", "<leader>bj", function()
  buf_utils.move(-(vim.v.count > 0 and vim.v.count or 1))
end, { desc = "Move buffer tab left" })

vim.keymap.set("n", "<leader>fw", "<cmd>w<cr>", { desc = "Write / Save Buffer" })
vim.keymap.set("n", "<leader>fW", "<cmd>w!<cr>", { desc = "Force Write Buffer" })

vim.keymap.set("i", "<C-BS>", "<C-w>")
vim.keymap.set("c", "<C-BS>", "<C-w>")
vim.keymap.set("i", "<C-H>", "<C-w>")
vim.keymap.set("c", "<C-H>", "<C-w>")

vim.keymap.set(
  "n",
  "<leader>by",
  [[:let @+=expand('%:p')<CR>]],
  { noremap = true, silent = true, desc = "Copy file path to clipboard" }
)
