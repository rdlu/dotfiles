---@module "lazy"
---@type LazySpec
return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false, -- Never set this value to "*"! Never!
  -- Remove opts = {} since we'll use config instead
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  config = function()
    local avante = require("avante")
    -- Get the default options
    local opts = {
      providers = {
        gemini25 = {
          __inherited_from = "gemini",
          model = "gemini-2.5-pro",
          timeout = 120000, -- Timeout in milliseconds
        },
      },
    }
    -- Add MCP Hub integration without overriding defaults
    -- opts.system_prompt = function()
    --   local hub = require("mcphub").get_hub_instance()
    --   return hub and hub:get_active_servers_prompt() or ""
    -- end
    -- opts.custom_tools = function()
    --   return {
    --     require("mcphub.extensions.avante").mcp_tool(),
    --   }
    -- end
    -- Setup with our options (will merge with defaults)
    avante.setup(opts)
  end,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- "ravitemer/mcphub.nvim", -- Required for MCP Hub integration
    --- The below dependencies are optional,
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
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
