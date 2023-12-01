-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>rw", "*ciw", { desc = "Replace inner word under cursor" })
vim.keymap.set("n", "<leader>rn", "*cgn", { desc = "Replace next word under cursor and jump" })
vim.keymap.set("n", "<leader>ri", ":%s/<c-r><c-w>/<c-r><c-w>/gc<c-f>$F/i", { desc = "Replace test" })

-- exit insert mode with jk
vim.keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "<ESC>" })
-- delete to null register
vim.keymap.set({ "n", "v" }, "d", '"xd', { noremap = true, silent = true, desc = "Delete" })
vim.keymap.set({ "n", "v" }, "D", '"xD', { noremap = true, silent = true, desc = "Delete" })
vim.keymap.set({ "n", "v" }, "x", '"xx', { noremap = true, silent = true, desc = "Delete" })

-- Remap K and J
vim.keymap.set({ "n", "v" }, "<leader>k", "K", { noremap = true, desc = "Keyword" })
vim.keymap.set({ "n", "v" }, "<leader>j", "J", { noremap = true, desc = "Join lines" })

-- Perusing code faster with K and J
vim.keymap.set({ "n", "v" }, "K", "5k", { noremap = true, desc = "Up faster" })
vim.keymap.set({ "n", "v" }, "J", "5j", { noremap = true, desc = "Down faster" })

vim.keymap.set(
  { "n", "v" },
  "<leader>Sw",
  ":MoveWord(1)<CR>'",
  { noremap = true, silent = true, desc = "Swap word forward" }
)
vim.keymap.set(
  { "n", "v" },
  "<leader>Sb",
  ":MoveWord(-1)<CR>'",
  { noremap = true, silent = true, desc = "Swap word back" }
)

local buf_utils = require("utils.buffer")
-- buffer management
vim.keymap.set("n", "<leader>bc", function()
  buf_utils.close()
end, { desc = "Close buffer" })
vim.keymap.set("n", "<leader>bC", function()
  buf_utils.close(0, true)
end, { desc = "Force close buffer" })
vim.keymap.set("n", "<leader>bl", function()
  buf_utils.move(vim.v.count > 0 and vim.v.count or 1)
end, { desc = "Move buffer tab right" })
vim.keymap.set("n", "<leader>bj", function()
  buf_utils.move(-(vim.v.count > 0 and vim.v.count or 1))
end, { desc = "Move buffer tab left" })

vim.keymap.set("n", "<leader>fw", "<cmd>w<cr>", { desc = "Write / Save Buffer" })
vim.keymap.set("n", "<leader>fW", "<cmd>w!<cr>", { desc = "Force Write Buffer" })

vim.keymap.set("n", "<leader>bw", "<cmd>w<cr>", { desc = "Write / Save Buffer" })
vim.keymap.set("n", "<leader>bW", "<cmd>w!<cr>", { desc = "Force Write Buffer" })

local c = {
  c = { "<cmd>ChatGPT<CR>", "ChatGPT", mode = { "n" } },
  e = { "<cmd>ChatGPTEditWithInstruction<CR>", "Edit with instruction", mode = { "n", "v" } },
  g = { "<cmd>ChatGPTRun grammar_correction<CR>", "Grammar Correction", mode = { "n", "v" } },
  t = { "<cmd>ChatGPTRun translate<CR>", "Translate", mode = { "n", "v" } },
  k = { "<cmd>ChatGPTRun keywords<CR>", "Keywords", mode = { "n", "v" } },
  u = { "<cmd>ChatGPTRun docstring<CR>", "Docstring", mode = { "n", "v" } },
  T = { "<cmd>ChatGPTRun add_tests<CR>", "Add Tests", mode = { "n", "v" } },
  o = { "<cmd>ChatGPTRun optimize_code<CR>", "Optimize Code", mode = { "n", "v" } },
  s = { "<cmd>ChatGPTRun summarize<CR>", "Summarize", mode = { "n", "v" } },
  b = { "<cmd>ChatGPTRun fix_bugs<CR>", "Fix Bugs", mode = { "n", "v" } },
  x = { "<cmd>ChatGPTRun explain_code<CR>", "Explain Code", mode = { "n", "v" } },
  r = { "<cmd>ChatGPTRun roxygen_edit<CR>", "Roxygen Edit", mode = { "n", "v" } },
  y = { "<cmd>ChatGPTRun code_readability_analysis<CR>", "Code Readability Analysis", mode = { "n", "v" } },
}

for key, value in pairs(c) do
  local command = value[1]
  local description = value[2]
  local lead = string.format("<leader>c%s", key)

  vim.keymap.set(value.mode, lead, command, { desc = description })
end
