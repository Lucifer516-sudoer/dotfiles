-- ~/.config/hypr/hyprland/layouts.lua
local layouts = { "dwindle", "master", "scrolling", "monocle" }

local function set_layout(name)
    local ws = hl.get_active_workspace()
    if not ws then return end
    hl.workspace_rule({ workspace = ws.name, layout = name })
    hl.exec_cmd("notify-send 'Layout' '" .. name .. "'")
end

local function cycle_layout()
    local ws = hl.get_active_workspace()
    if not ws then return end
    local nxt = layouts[1]
    for i, l in ipairs(layouts) do
        if l == ws.tiled_layout then
            nxt = layouts[(i % #layouts) + 1]
            break
        end
    end
    set_layout(nxt)
end

local mainMod = "SUPER"
for i, name in ipairs(layouts) do
    hl.bind(mainMod .. " + ALT + " .. i, function() set_layout(name) end)
end
hl.bind(mainMod .. " + ALT + L", cycle_layout)
