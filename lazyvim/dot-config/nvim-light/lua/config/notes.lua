-- Note vaults for obsidian.nvim and dotmd. The real ones live in
-- ~/.dotfiles-private (lua/private/notes.lua, same shape); without it, one
-- generic vault.
local ok, notes = pcall(require, "private.notes")
if ok then
  return notes
end
return {
  workspaces = { { name = "Notes", path = "~/Documents/Notes" } },
  root = "~/Documents/Notes", -- dotmd's root_dir
}
