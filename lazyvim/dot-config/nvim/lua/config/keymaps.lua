-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true

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

vim.keymap.set({ "n", "v" }, "<leader>a", "", { silent = true, desc = "+ AI" })
vim.keymap.set(
  { "n", "v" },
  "<leader>af",
  "<cmd>CodeCompanionActions<cr>",
  { noremap = true, silent = true, desc = "CodeCompanionActions" }
)
vim.keymap.set(
  { "n", "v" },
  "<leader>aa",
  "<cmd>CodeCompanionChat Toggle<cr>",
  { noremap = true, silent = true, desc = "CodeCompanionChat" }
)
vim.keymap.set("n", "<leader>ad", function()
  require("codecompanion").prompt("docs")
end, { noremap = true, silent = true, desc = "CodeCompanion docs prompt" })
vim.keymap.set(
  "v",
  "ga",
  "<cmd>CodeCompanionChat Add<cr>",
  { noremap = true, silent = true, desc = "Add to CodeCompanionChat" }
)

vim.cmd([[cab cc CodeCompanion]])
