return {
  { "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      options = { section_separators = '', component_separators = '' },
    }
  }
}
