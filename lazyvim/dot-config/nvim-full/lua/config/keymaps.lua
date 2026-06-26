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

vim.keymap.set({ "n", "v" }, "gR", "", { silent = true, desc = "+search/replace" })

vim.keymap.set({ "n", "v" }, "<leader>a", "", { silent = true, desc = "+ AI" })

-- vim-herdr-navigation — seamless <C-h/j/k/l> window nav that crosses into herdr
-- panes at a split edge (falls back to tmux when not under herdr). Pairs with the
-- vim-herdr-navigation herdr plugin: it's bound to Alt-h/j/k/l on the herdr side,
-- and navigate.sh forwards the Ctrl chords here when Neovim is the focused pane.
-- Overrides LazyVim's plain <C-w> window-nav maps (loaded later, so it wins).
-- (Insert/cmdline <C-h> stays mapped to <C-w> above; these are normal-mode only.)
local function herdr_nav(wincmd, dir)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= prev then
    return -- moved within Neovim
  end
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == "" then
      herdr = "herdr"
    end
    vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--current" })
  elseif vim.env.TMUX and vim.env.TMUX ~= "" then
    local tmux = { left = "Left", down = "Down", up = "Up", right = "Right" }
    pcall(vim.cmd, "TmuxNavigate" .. tmux[dir])
  end
end

for _, m in ipairs({
  { "<C-h>", "h", "left" },
  { "<C-j>", "j", "down" },
  { "<C-k>", "k", "up" },
  { "<C-l>", "l", "right" },
}) do
  vim.keymap.set("n", m[1], function()
    herdr_nav(m[2], m[3])
  end, { silent = true, noremap = true, desc = "Navigate " .. m[3] .. " (vim/herdr)" })
end
