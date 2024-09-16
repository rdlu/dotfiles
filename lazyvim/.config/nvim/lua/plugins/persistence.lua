return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    need = 3,
    branch = true, -- use git branch to save session
  },
  -- stylua: ignore
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    { "<leader>qS", function() require("persistence").select() end, desc = "Select Session" },
  },
}
