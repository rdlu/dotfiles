return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "hrsh7th/cmp-emoji" },
      { "jmbuhr/otter.nvim" },
      { "FelipeLema/cmp-async-path" },
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.close()
          else
            cmp.complete()
          end
        end, { "i", "s" }),
        ["<C-e>"] = cmp.mapping.close(),
        ["<CR>"] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- this way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })

      opts.sources = vim.tbl_extend("force", opts.sources, {
        -- Copilot Source
        { name = "copilot", group_index = 2 },
        -- Other Sources
        { name = "nvim_lsp", group_index = 2 },
        { name = "otter", group_index = 2 },
        { name = "async_path", group_index = 2 },
        { name = "luasnip", group_index = 2, max_item_count = 5 },
        { name = "buffer", group_index = 2, keyword_length = 3, max_item_count = 3 },
        { name = "treesitter", group_index = 3, keyword_length = 5, max_item_count = 3 },
        { name = "emoji", group_index = 3, keyword_length = 3, max_item_count = 3 },
        { name = "path", enabled = false },
      })
    end,
  },
}

-- setup = function()
--   local cmp = require('cmp')
--   local luasnip = require('luasnip')
--
--   cmp.setup({
--     snippet = {
--       expand = function(args)
--         require('luasnip').lsp_expand(args.body)
--       end,
--     },
--     mapping = {
--       ['<C-p>'] = cmp.mapping.select_prev_item(),
--       ['<C-n>'] = cmp.mapping.select_next_item(),
--       ['<C-d>'] = cmp.mapping.scroll_docs(-4),
--       ['<C-f>'] = cmp.mapping.scroll_docs(4),
--       ['<C-Space>'] = cmp.mapping.complete(),
--       ['<C-e>'] = cmp.mapping.close(),
--       ['<CR>'] = cmp.mapping.confirm({
--         behavior = cmp.ConfirmBehavior.Replace,
--         select = true,
--       }),
--       ['<Tab>'] = cmp.mapping(function(fallback)
--         if cmp.visible() then
--           cmp.select_next_item()
--         elseif luasnip.expand_or_jumpable() then
--           vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-expand-or-jump', true, true, true), '')
--         else
--           fallback()
--         end
--       end, {
--         'i',
--         's',
--       }),
--       ['<S-Tab>'] = cmp.mapping(function(fallback)
--         if cmp.visible() then
--           cmp.select_prev_item()
--         elseif luasnip.jumpable(-1) then
--           vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>luasnip-jump-prev', true, true, true), '')
--         else
--           fallback()
--         end
--       end, {
--         'i',
--         's',
--       }),
--     },
--     sources = {
--       { name = 'nvim_lsp' },
--       { name = 'luasnip' },
--       { name = 'buffer' },
--       { name = 'path' },
--       { name = 'nvim_lua' },
--       { name = 'calc' },
--       { name = 'emoji' },
--     },
--   })
-- end,
