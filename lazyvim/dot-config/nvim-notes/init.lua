-- nvim-notes: lean neovim for note editing (clin's external editor; `nvn` in
-- fish). Markdown via the bundled treesitter parsers, shared spell with
-- nvim-light (spell/ symlink), just enough to follow [[wikilinks]], plus two
-- plugins via the built-in vim.pack manager (auto-cloned on first launch):
-- which-key and a slice of snacks (picker/zen/notifier).

vim.g.mapleader = ' '
vim.o.number = true
vim.o.signcolumn = 'no'
vim.o.wrap = true
vim.o.linebreak = true
vim.o.breakindent = true
vim.o.conceallevel = 2 -- hide md syntax (ts queries conceal *emphasis*, [links])
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.clipboard = 'unnamedplus'
vim.o.autowriteall = true -- notes: never lose an edit on :e/quit

-- Move by screen line so soft wrap feels native.
vim.keymap.set({ 'n', 'x' }, 'j', 'gj')
vim.keymap.set({ 'n', 'x' }, 'k', 'gk')

-- Follow the [[wikilink]] under the cursor (clin/Obsidian style). Looks for
-- <target>.md anywhere under the vault root (dir with .obsidian or .git);
-- a missing target opens a new buffer next to the current note.
local function follow_wikilink()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local target
  for from, inner, to in line:gmatch('()%[%[(..-)%]%]()') do
    if col >= from and col < to then
      target = inner:match('^([^|#]+)') -- drop |alias and #heading
      break
    end
  end
  if not target or target == '' then return end
  target = vim.trim(target)
  local buf_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  local root = vim.fs.root(0, { '.obsidian', '.git' }) or buf_dir
  local found
  if target:find('/') then
    local candidate = vim.fs.joinpath(root, target .. '.md')
    found = vim.uv.fs_stat(candidate) and candidate or nil
  else
    found = vim.fs.find(target .. '.md', { path = root, type = 'file', limit = 1 })[1]
  end
  vim.cmd.edit(vim.fn.fnameescape(found or vim.fs.joinpath(buf_dir, target .. '.md')))
end

vim.pack.add({
  'https://github.com/folke/which-key.nvim',
  'https://github.com/folke/snacks.nvim',
  'https://github.com/folke/flash.nvim',
  'https://github.com/nvim-mini/mini.ai',
})

require('which-key').setup({})
require('flash').setup({})
require('mini.ai').setup() -- extra a/i textobjects: arguments, quotes, brackets pairs, …
require('snacks').setup({
  picker = { enabled = true },
  notifier = { enabled = true },
  zen = { enabled = true },
})

-- flash: s to jump anywhere, S for treesitter-scope select; f/F/t/T get labels
vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('flash').jump() end, { desc = 'Flash jump' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('flash').treesitter() end, { desc = 'Flash treesitter select' })

vim.keymap.set('n', '<leader><leader>', function() Snacks.picker.files() end, { desc = 'Find note' })
vim.keymap.set('n', '<leader>/', function() Snacks.picker.grep() end, { desc = 'Grep notes' })
vim.keymap.set('n', '<leader>r', function() Snacks.picker.recent() end, { desc = 'Recent notes' })
vim.keymap.set('n', '<leader>z', function() Snacks.zen() end, { desc = 'Zen writing mode' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function(ev)
    vim.treesitter.start(ev.buf)
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { 'en', 'pt' }
    vim.opt_local.formatoptions:append('ro') -- continue lists on <CR>/o
    vim.keymap.set('n', '<CR>', follow_wikilink, { buffer = ev.buf, desc = 'Follow [[wikilink]]' })
  end,
})
