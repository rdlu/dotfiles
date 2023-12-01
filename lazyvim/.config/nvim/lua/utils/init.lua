local M = {}

--- Merge extended options with a default table of options
---@param default? table The default table that you want to merge into
---@param opts? table The new options that should be merged with the default table
---@return table # The merged table
function M.extend_tbl(default, opts)
  opts = opts or {}
  return default and vim.tbl_deep_extend("force", default, opts) or opts
end

--- Serve a notification with a title of AstroNvim
---@param msg string The notification body
---@param type number|nil The type of the notification (:help vim.log.levels)
---@param opts? table The nvim-notify options to use (:help notify-options)
function M.notify(msg, type, opts)
  vim.schedule(function()
    vim.notify(msg, type, M.extend_tbl({ title = "Utils" }, opts))
  end)
end

--- Trigger an AstroNvim user event
---@param event string The event name to be appended to Astro
function M.event(event)
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "Utils" .. event })
  end)
end

function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.plugins[plugin] ~= nil
end

return M
