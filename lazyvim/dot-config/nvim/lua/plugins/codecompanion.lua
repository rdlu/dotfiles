return {
  "olimorris/codecompanion.nvim",
  config = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    {
      "Davidyz/VectorCode",
      version = "*",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },
  opts = {
    strategies = {
      chat = {
        adapter = "gemini",
      },
      inline = {
        adapter = "anthropic",
      },
    },
  },
}
