local m = require('mapx').setup {
  whichkey = true,
  enableCountArg = false,
  debug = vim.g.mapxDebug or false,
}

-- stylua: ignore start
-- Disable C-z suspend
m.map([[<C-z>]], [[<Nop>]])
m.mapbang([[<C-z>]], [[<Nop>]])

m.noremap([[J]], [[5j]], "Jump down")
m.noremap([[K]], [[5k]], "Jump up")
m.xnoremap([[J]], [[5j]], "Jump down")
m.xnoremap([[K]], [[5k]], "Jump up")

-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    -- mappings seen under group name "Buffer"
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(function(bufnr) require("astronvim.utils.buffer").close(bufnr) end)
      end,
      desc = "Pick to close",
    },
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
}


