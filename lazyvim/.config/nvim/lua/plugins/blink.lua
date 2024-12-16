return {
  "saghen/blink.cmp",
  opts = {
    keymap = { preset = "super-tab", ["<CR>"] = { "accept", "fallback" } },
    sources = {
      default = { "snippets", "lsp", "buffer", "path" },
    },
  },
}
