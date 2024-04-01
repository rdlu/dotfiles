return {
  -- Disable default Tab Key mappings in LuaSnip
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = cmp.mapping.preset.insert({
        -- Press Tab to autocomplete
        ["<Tab>"] = cmp.mapping.confirm({ select = true }),
      })
    end,
  },
}
