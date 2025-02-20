return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
      hints = { enabled = true },
      auto_suggestions_provider = "haiku",
      provider = "claude",
      behaviour = {
        auto_suggestions = false,
      },
      vendors = {
        haiku = {
          __inherited_from = "claude",
          model = "claude-3-5-haiku-20241022",
          temperature = 0,
          max_tokens = 4096,
        },
        o3 = {
          __inherited_from = "openai",
          model = "o3-mini",
        },
      },
      suggestion = {
        debounce = 1000,
      },
    },
    build = LazyVim.is_win() and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" or "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    ft = function(_, ft)
      vim.list_extend(ft, { "Avante" })
    end,
    opts = function(_, opts)
      opts.file_types = vim.list_extend(opts.file_types or {}, { "Avante" })
    end,
  },
}
