-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Unmap mappings used by tmux plugin
vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")
vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>")
vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>")
vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>")
vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>")

-- exit insert mode with jk
vim.keymap.set("i", "jk", "<ESC>", { noremap = true, silent = true, desc = "<ESC>" })

-- Perusing code faster with K and J
vim.keymap.set({ "n", "v" }, "K", "5k", { noremap = true, desc = "Up faster" })
vim.keymap.set({ "n", "v" }, "J", "5j", { noremap = true, desc = "Down faster" })

-- Remap K and J
vim.keymap.set({ "n", "v" }, "<leader>k", "K", { noremap = true, desc = "Keyword" })
vim.keymap.set({ "n", "v" }, "<leader>j", "J", { noremap = true, desc = "Join lines" })

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

local buf_utils = require("utils.buffer")
-- buffer management
map("n", "<leader>bc", function()
  buf_utils.close()
end, { desc = "Close buffer" })
map("n", "<leader>bC", function()
  buf_utils.close(0, true)
end, { desc = "Force close buffer" })
map("n", "<leader>bl", function()
  buf_utils.move(vim.v.count > 0 and vim.v.count or 1)
end, { desc = "Move buffer tab right" })
map("n", "<leader>bj", function()
  buf_utils.move(-(vim.v.count > 0 and vim.v.count or 1))
end, { desc = "Move buffer tab left" })

map("n", "<leader>fw", "<cmd>w<cr>", { desc = "Write / Save Buffer" })
map("n", "<leader>fW", "<cmd>w!<cr>", { desc = "Force Write Buffer" })

map("n", "<leader>bw", "<cmd>w<cr>", { desc = "Write / Save Buffer" })
map("n", "<leader>bW", "<cmd>w!<cr>", { desc = "Force Write Buffer" })
