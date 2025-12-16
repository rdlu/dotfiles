return {
  -- Override the LSP configuration to use Expert instead of the default
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Disable the default elixirls
        elixirls = false,
        lexical = false,
        expert = {},
      },
    },
  },
}
