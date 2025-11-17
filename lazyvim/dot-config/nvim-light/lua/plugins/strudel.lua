return {
  "gruvw/strudel.nvim",
  build = "bun install",
  config = function()
    local strudel = require("strudel")
    strudel.setup({ -- Strudel web user interface related options
      ui = {
        -- Maximise the menu panel
        -- (optional, default: true)
        maximise_menu_panel = true,
        -- Hide the Strudel menu panel (and handle)
        -- (optional, default: false)
        hide_menu_panel = false,
        -- Hide the default Strudel top bar (controls)
        -- (optional, default: false)
        hide_top_bar = false,
        -- Hide the Strudel code editor
        -- (optional, default: false)
        hide_code_editor = false,
        -- Hide the Strudel eval error display under the editor
        -- (optional, default: false)
        hide_error_display = false,
      },
      -- Set to `true` to automatically trigger the code evaluation after saving the buffer content
      -- Only works if the playback was already started (doesn't start the playback on save)
      -- (optional, default: false)
      update_on_save = true,
      -- Enable two-way cursor position sync between Neovim and Strudel editor.
      -- (optional, default: true)
      sync_cursor = true,
      -- Report evaluation errors from Strudel as Neovim notifications.
      -- (optional, default: true)
      report_eval_errors = true,
    })

    vim.keymap.set("n", "<leader>t", "", { desc = "+sTrudel" })
    vim.keymap.set("n", "<leader>tl", strudel.launch, { desc = "Launch Strudel" })
    vim.keymap.set("n", "<leader>tq", strudel.quit, { desc = "Quit Strudel" })
    vim.keymap.set("n", "<leader>tt", strudel.toggle, { desc = "Strudel Toggle Play/Stop" })
    vim.keymap.set("n", "<leader>tu", strudel.update, { desc = "Strudel Update" })
    vim.keymap.set("n", "<leader>ts", strudel.stop, { desc = "Strudel Stop Playback" })
    vim.keymap.set("n", "<leader>tb", strudel.set_buffer, { desc = "Strudel set current buffer" })
    vim.keymap.set("n", "<leader>tx", strudel.execute, { desc = "Strudel set current buffer and update" })
  end,
}
