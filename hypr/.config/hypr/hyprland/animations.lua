-- Hyprland 0.55+ Lua Configuration
-- Since Hyprland 0.55, config is driven by hl.config()/hl.curve()/hl.animation()
-- calls rather than a plain returned table. See:
-- https://wiki.hypr.land/Configuring/Basics/Variables/
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 2,
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 8,
        rounding_power = 4,
        active_opacity = 1.00,
        inactive_opacity = 0.92,
        shadow = {
            enabled = true,
            range = 6,
            render_power = 3,
            color = "rgba(000000CC)",
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 1,
            vibrancy = 0.14,
        },
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
    },
})

-- Bezier curve definitions
hl.curve("default", { type = "bezier", points = { { 0.22, 1.00 }, { 0.36, 1.00 } } })
hl.curve("smoothInOut", { type = "bezier", points = { { 0.40, 0.00 }, { 0.20, 1.00 } } })
hl.curve("quick", { type = "bezier", points = { { 0.16, 0.84 }, { 0.44, 1.00 } } })
hl.curve("pop", { type = "bezier", points = { { 0.20, 1.00 }, { 0.30, 1.00 } } })
-- "linear" is a builtin curve name in Hyprland; no need to redefine it.

-- Animation rules
hl.animation({ leaf = "global", enabled = true, speed = 8.0, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.0, bezier = "smoothInOut" })
hl.animation({ leaf = "windows", enabled = true, speed = 5.5, bezier = "smoothInOut" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.2, bezier = "pop", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.0, bezier = "linear", style = "popin 92%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.2, bezier = "quick" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.1, bezier = "quick" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.6, bezier = "smoothInOut" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.8, bezier = "smoothInOut" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.6, bezier = "smoothInOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.6, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.9, bezier = "quick" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.3, bezier = "quick" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.6, bezier = "smoothInOut", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.1, bezier = "quick", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.8, bezier = "smoothInOut", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6.5, bezier = "quick" })
