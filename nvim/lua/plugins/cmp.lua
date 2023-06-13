return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      { "hrsh7th/cmp-emoji" },
      { "jmbuhr/otter.nvim" },
      { "FelipeLema/cmp-async-path" },
      { "onsails/lspkind.nvim" },
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
        ["<CR>"] = cmp.mapping({
          i = function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
              cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
            else
              fallback()
            end
          end,
          s = cmp.mapping.confirm({ select = true }),
          c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() and has_words_before() then
            if cmp.get_active_entry() then
              cmp.select_next_item()
            else
              -- trying to get the real first item after async events
              cmp.select_prev_item({ count = cmp.core.view:get_offset() })
              cmp.select_next_item()
            end
            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
            -- this way you will only jump inside the snippet region
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() and has_words_before() then
            cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })

      opts.sources = vim.tbl_extend("force", opts.sources, {
        { name = "treesitter", keyword_length = 5, max_item_count = 3 },
        { name = "nvim_lsp", max_item_count = 5 },
        { name = "luasnip", max_item_count = 5 },
        { name = "async_path" },
        { name = "buffer", keyword_length = 3, max_item_count = 3 },
        { name = "copilot", keyword_length = 4 },
        { name = "spell", keyword_length = 4, priority = 5, keyword_pattern = [[\w\+]], max_item_count = 3 },
        { name = "path", enabled = false },
      })

      opts.preselect = "None"

      opts.sorting = {
        priority_weight = 2,
        comparators = {
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.locality,
          cmp.config.compare.recently_used,
          cmp.config.compare.score,

          -- copied from cmp-under, but I don't think I need the plugin for this.
          -- I might add some more of my own.
          function(entry1, entry2)
            local _, entry1_under = entry1.completion_item.label:find("^_+")
            local _, entry2_under = entry2.completion_item.label:find("^_+")
            entry1_under = entry1_under or 0
            entry2_under = entry2_under or 0
            if entry1_under > entry2_under then
              return false
            elseif entry1_under < entry2_under then
              return true
            end
          end,

          cmp.config.compare.kind,
          cmp.config.compare.sort_text,
          cmp.config.compare.length,
          cmp.config.compare.order,
        },
      }

      opts.formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, vim_item)
          local kind = require("lspkind").cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            symbol_map = { Copilot = "" },
          })(entry, vim_item)
          local strings = vim.split(kind.kind, "%s", { trimempty = true })
          if entry.source.name == "nvim_lsp" and strings[2] == "Snippet" then
            strings[2] = "LSP Snippet"
          end
          kind.kind = " " .. (strings[1] or "") .. " "
          kind.menu = "    " .. (strings[2] or strings[1] or "")
          return kind
        end,
      }

      opts.window = {
        completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          col_offset = 0,
          side_padding = 0,
        },
      }
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
