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
        model = "gpt-4-turbo-preview",
      },
    }
    require("chatgpt").setup(cfg)

    local wk = require("which-key")
    wk.register({
      m = {
        name = "ChatGPT",
        c = { "<cmd>ChatGPT<CR>", "*ChatGPT*" },
        a = { "<cmd>ChatGPTActAs<CR>", "ChatGPT Act As" },
        e = { "<cmd>ChatGPTEditWithInstruction<CR>", "*Edit with instruction*" },
        g = { "<cmd>ChatGPTRun grammar_correction<CR>", "Grammar Correction" },
        t = { "<cmd>ChatGPTRun translate<CR>", "Translate" },
        k = { "<cmd>ChatGPTRun keywords<CR>", "Keywords" },
        d = { "<cmd>ChatGPTRun docstring<CR>", "Docstring" },
        T = { "<cmd>ChatGPTRun add_tests<CR>", "Add Tests" },
        o = { "<cmd>ChatGPTRun optimize_code<CR>", "Optimize Code" },
        s = { "<cmd>ChatGPTRun summarize<CR>", "Summarize" },
        b = { "<cmd>ChatGPTRun fix_bugs<CR>", "Fix Bugs" },
        x = { "<cmd>ChatGPTRun explain_code<CR>", "Explain Code" },
        r = { "<cmd>ChatGPTRun roxygen_edit<CR>", "Roxygen Edit" },
        y = { "<cmd>ChatGPTRun code_readability_analysis<CR>", "Code Readability Analysis" },
      },
    }, { prefix = "<leader>", mode = { "n", "v" } })
  end,
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
}
