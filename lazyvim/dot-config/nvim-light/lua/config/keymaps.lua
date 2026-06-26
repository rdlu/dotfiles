-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- add good words to specific spell dicitionary
local function add_word_to_lang(lang)
  -- Find word under cursor
  local word = vim.fn.expand("<cword>")
  if word == "" then
    print("No word under cursor.")
    return
  end

  -- Save original language and spellfile
  local original_lang = vim.opt.spelllang:get()
  local original_spellfile = vim.opt.spellfile

  -- Get the current language file
  local spellfile_path = vim.fn.expand(string.format("~/.dotfiles/nvim/spell/%s.utf-8.add", lang))

  -- Temporarily set spelllang to only the desired language
  vim.opt.spelllang = { lang }
  vim.opt.spellfile = spellfile_path

  -- Mark word as good and save spellfile
  vim.cmd("silent! spellgood " .. word)
  vim.cmd("silent! mkspell! " .. spellfile_path)

  -- Restore original settings
  vim.opt.spelllang = original_lang
  vim.opt.spellfile = original_spellfile

  print("Added '" .. word .. "' to " .. lang)
end

vim.keymap.set("n", "zg", "", { desc = "+Spelling" })
vim.keymap.set("n", "zgp", function()
  add_word_to_lang("pt_br")
end, { desc = "PT-BR Add to dict" })
vim.keymap.set("n", "zge", function()
  add_word_to_lang("en")
end, { desc = "EN Add to dict" })

-- vim-herdr-navigation — seamless <C-h/j/k/l> window nav that crosses into herdr
-- panes at a split edge (falls back to tmux when not under herdr). Pairs with the
-- vim-herdr-navigation herdr plugin: it's bound to Alt-h/j/k/l on the herdr side,
-- and navigate.sh forwards the Ctrl chords here when Neovim is the focused pane.
-- Overrides LazyVim's plain <C-w> window-nav maps (loaded later, so it wins).
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
