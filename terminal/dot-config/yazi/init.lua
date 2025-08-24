-- Show symlink in status bar
Status:children_add(function(self)
	local h = self._current.hovered
	if h and h.link_to then
		return " -> " .. tostring(h.link_to)
	else
		return ""
	end
end, 3300, Status.LEFT)
-- Show user/group of files in status bar
Status:children_add(function()
	local h = cx.active.current.hovered
	if not h or ya.target_family() ~= "unix" then
		return ""
	end
	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		":",
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		" ",
	})
end, 500, Status.RIGHT)
-- Plugins
-- Copy file content (Use "ya pkg add AnirudhG07/plugins-yazi:copy-file-contents" to install on new environments)
require("copy-file-contents"):setup({
	append_char = "\n",
	notification = true,
})
-- Full-border line (Use "ya pkg add yazi-rs/plugins:full-border")
require("full-border"):setup({
	type = ui.Border.PLAIN,
})
