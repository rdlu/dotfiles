return {
  "github/copilot.vim",
  config = function()
    vim.keymap.set("i", "<M-.>", 'copilot#Accept("\\<CR>")', {
      expr = true,
      replace_keycodes = false,
      silent = true,
    })

    vim.keymap.set("i", "<M-,>", "copilot#AcceptWord()", {
      expr = true,
      replace_keycodes = false,
      silent = true,
    })

    vim.keymap.set("i", "<C-_>", "copilot#AcceptLine()", {
      expr = true,
      replace_keycodes = false,
      silent = true,
    })
  end,
}
