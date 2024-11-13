return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lexical = {
          -- Lexical doesn't support pipe manipulation commands like elixirls did
          -- but it provides better performance and more modern features
          mason = true,
          settings = {
            elixirLS = {
              dialyzerEnabled = true,
              enableTestLenses = true,
            },
          },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "elixir", "heex", "eex" })
      vim.treesitter.language.register("markdown", "livebook")
    end,
  },
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = {
      "jfpedroza/neotest-elixir",
    },
    opts = {
      adapters = {
        ["neotest-elixir"] = {
          post_process_command = function(cmd)
            return { "env", "MIX_ENV=test", unpack(cmd) }
          end,
        },
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.diagnostics.credo.with({
          condition = function(utils)
            return utils.root_has_file(".credo.exs")
          end,
        }),
      })
    end,
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = {
        elixir = { "credo" },
      }

      opts.linters = {
        credo = {
          condition = function(ctx)
            return vim.fs.find({ ".credo.exs" }, { path = ctx.filename, upward = true })[1]
          end,
        },
      }
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    optional = true,
    ft = function(_, ft)
      vim.list_extend(ft, { "livebook" })
    end,
  },
}
