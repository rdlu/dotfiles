return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  config = function()
    local cfg = {
      openai_params = {
        model = "gpt-4-1106-preview",
        max_tokens = 4096,
        -- model = "gpt-3.5-turbo-1106"
      },
      openai_edit_params = {
        -- model = "gpt-3.5-turbo-1106"
        model = "gpt-4-1106-preview",
      },
    }
    require("chatgpt").setup(cfg)
  end,
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
}
