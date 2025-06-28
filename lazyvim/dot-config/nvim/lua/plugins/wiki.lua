-- dotmd.lua
return {
  "y3owk1n/dotmd.nvim",
  version = "*", -- remove this if you want to use the `main` branch
  ---@type DotMd.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    root_dir = "~/Documents/Suika Box/", -- set it to your desired directory or remain at it is
    default_split = "float", -- or "vertical" or "horizontal" or "none" based on your preference
    rollover_todo = {
      enabled = true, -- enable rollover
    },
    picker = "snacks", -- or "fzf" or "telescope" or "mini" based on your preference
  },

  keys = {
    {
      "<leader>z",
      function() end,
      desc = "+notes",
    },

    {
      "<leader>zc",
      function()
        require("dotmd").create_note()
      end,
      desc = "[DotMd] Create new note",
    },
    {
      "<leader>zt",
      function()
        require("dotmd").create_todo_today()
      end,
      desc = "[DotMd] Create todo for today",
    },
    {
      "<leader>zi",
      function()
        require("dotmd").inbox()
      end,
      desc = "[DotMd] Inbox",
    },
    {
      "<leader>zj",
      function()
        require("dotmd").create_journal()
      end,
      desc = "[DotMd] Create journal",
    },
    {
      "<leader>zp",
      function()
        require("dotmd").navigate("previous")
      end,
      desc = "[DotMd] Navigate to previous todo",
    },
    {
      "<leader>zn",
      function()
        require("dotmd").navigate("next")
      end,
      desc = "[DotMd] Navigate to next todo",
    },
    {
      "<leader>zo",
      function()
        require("dotmd").open({
          pluralise_query = true, -- recommended
        })
      end,
      desc = "[DotMd] Open",
    },
    {
      "<leader>zoa",
      function()
        require("dotmd").pick()
      end,
      desc = "[DotMd] Everything",
    },
    {
      "<leader>zoA",
      function()
        require("dotmd").pick({
          grep = true,
        })
      end,
      desc = "[DotMd] Search everything grep",
    },
    {
      "<leader>zon",
      function()
        require("dotmd").pick({
          type = "notes",
        })
      end,
      desc = "[DotMd] Search notes",
    },
    {
      "<leader>zoN",
      function()
        require("dotmd").pick({
          type = "notes",
          grep = true,
        })
      end,
      desc = "[DotMd] Search notes grep",
    },
    {
      "<leader>zot",
      function()
        require("dotmd").pick({
          type = "todos",
        })
      end,
      desc = "[DotMd] Search todos",
    },
    {
      "<leader>zoT",
      function()
        require("dotmd").pick({
          type = "todos",
          grep = true,
        })
      end,
      desc = "[DotMd] Search todos grep",
    },
    {
      "<leader>zoj",
      function()
        require("dotmd").pick({
          type = "journals",
        })
      end,
      desc = "[DotMd] Search journal",
    },
    {
      "<leader>zoJ",
      function()
        require("dotmd").pick({
          type = "journals",
          grep = true,
        })
      end,
      desc = "[DotMd] Search journal grep",
    },
  },
}
