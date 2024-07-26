return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  config = function()
    local cfg = {
      openai_params = {
        model = "gpt-4o",
        max_tokens = 4096,
        -- model = "gpt-3.5-turbo-1106"
      },
      openai_edit_params = {
        -- model = "gpt-3.5-turbo-1106"
        model = "gpt-4o",
      },
    }
    require("chatgpt").setup(cfg)

    local wk = require("which-key")
    wk.add({
      {
        mode = { "n", "v" },
        { "<leader>m", group = "ChatGPT" },
        { "<leader>mT", "<cmd>ChatGPTRun add_tests<CR>", desc = "Add Tests" },
        { "<leader>ma", "<cmd>ChatGPTActAs<CR>", desc = "ChatGPT Act As" },
        { "<leader>mb", "<cmd>ChatGPTRun fix_bugs<CR>", desc = "Fix Bugs" },
        { "<leader>mc", "<cmd>ChatGPT<CR>", desc = "*ChatGPT*" },
        { "<leader>md", "<cmd>ChatGPTRun docstring<CR>", desc = "Docstring" },
        { "<leader>me", "<cmd>ChatGPTEditWithInstruction<CR>", desc = "*Edit with instruction*" },
        { "<leader>mg", "<cmd>ChatGPTRun grammar_correction<CR>", desc = "Grammar Correction" },
        { "<leader>mk", "<cmd>ChatGPTRun keywords<CR>", desc = "Keywords" },
        { "<leader>mo", "<cmd>ChatGPTRun optimize_code<CR>", desc = "Optimize Code" },
        { "<leader>mr", "<cmd>ChatGPTRun roxygen_edit<CR>", desc = "Roxygen Edit" },
        { "<leader>ms", "<cmd>ChatGPTRun summarize<CR>", desc = "Summarize" },
        { "<leader>mt", "<cmd>ChatGPTRun translate<CR>", desc = "Translate" },
        { "<leader>mx", "<cmd>ChatGPTRun explain_code<CR>", desc = "Explain Code" },
        { "<leader>my", "<cmd>ChatGPTRun code_readability_analysis<CR>", desc = "Code Readability Analysis" },
      },
    })
  end,
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
}
