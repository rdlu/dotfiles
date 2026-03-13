return {
  "preservim/vim-pencil",
  ft = { "markdown", "text", "tex" },
  init = function()
    vim.g["pencil#wrapModeDefault"] = "soft"
  end,
  cmd = { "Pencil", "PencilSoft", "PencilHard", "PencilOff", "PencilToggle" },
}
