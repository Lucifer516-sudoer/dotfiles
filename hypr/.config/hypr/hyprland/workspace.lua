-- hyprland/workspace.lua
-- Workspace helper: names and example rules

local M = {}

M.names = {
    "1:term",
    "2:web",
    "3:code",
    "4:media",
    "5:chat",
}

-- Example: create a special scratchpad workspace rule (if needed elsewhere)
hl.workspace_rule({ workspace = "special:magic", gaps_out = 0, gaps_in = 0 })

return M
