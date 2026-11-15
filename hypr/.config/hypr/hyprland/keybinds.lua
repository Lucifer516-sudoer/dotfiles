-- ~/.config/hypr/hyprland/keybinds.lua
-- Converted from keybinds.conf to the Hyprland Lua config API (v0.55+)
-- require("hyprland.keybinds") from your hyprland.lua

local programs         = require("hyprland.programs")
local terminal         = programs.terminal     -- Terminal
local fileManager      = programs.file_manager -- FileManager
local menu             = programs.menu         -- Menu
local clipboardManager = programs
    .clipboard_manager                         --"sh -c \"cliphist list | wofi --dmenu | cliphist decode | wl-copy\""

local mainMod          = "SUPER"

----------------
---- APPS ------
----------------
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))

-- I guess this is a bad way, but i dont care
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("code ~/dev/dotfiles/"))

------------------------
---- WINDOW ACTIONS ----
------------------------
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 0 }))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())       -- dwindle mode toggle
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit")) -- dwindle split toggle

-- Keybinds helper
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("~/dev/dotfiles/hypr/.config/hypr/scripts/show_keybinds.sh"))

-- Keybind to switch wallpaper using my custom tool I wrote (Ghostty terminal)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/rofi_wallpaper_carousel.sh"))

-------------------------------
---- FOCUS NAVIGATION ---------
-------------------------------
-- Vim keys
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

-- Arrow keys
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))

-------------------------------
---- MOVE WINDOWS -------------
-------------------------------
-- Shift + vim keys
-- hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
-- hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
-- hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
-- hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Shift + normal arrow keys
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }), { repeating = false })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }), { repeating = false })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }), { repeating = false })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { repeating = false })


-------------------------------
---- RESIZE WINDOWS -----------
-------------------------------
-- Ctrl + vim keys
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })

-- Ctrl + arrow keys
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })

-------------------------------
---- WORKSPACES (1-10) --------
-------------------------------
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad / special workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-------------------------------
---- MOUSE ACTIONS ------------
-------------------------------
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-------------------------------
---- SCREENSHOT ---------------
-------------------------------
-- bind = , Print, exec, grim -g "$(slurp)" - | satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png
hl.bind("Print", hl.dsp.exec_cmd("caelestia screenshot"))
-- bind = SHIFT, Print, exec, grim - | satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d-%H:%M:%S').png

-------------------------------
---- CLIPBOARD MANAGER --------
-------------------------------
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(clipboardManager))

-------------------------------
---- COLOR PICKER -------------
-------------------------------
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd("hyprpicker -a"))

-------------------------------
---- LOGOUT MENU --------------
-------------------------------
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("wlogout"))

-------------------------------
---- Hyprlock --------------
-------------------------------
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))

-------------------------------
---- BRIGHTNESS & VOLUME ------
-------------------------------
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-------------------------------
---- NOTIFICATION STUFF -------
-------------------------------
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client --close-all"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("~/dotfiles/scripts/toggle_dnd.sh"))

-------------------------------
---- CAELESTIA SHELL -----------
-------------------------------
-- hl.bind(mainMod .. " + space", hl.dsp.global("caelestia:launcher"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("caelestia emoji -p"))
hl.bind(mainMod .. "+ CTRL + ALT + L", hl.dsp.exec_cmd("/.config/hyprlock/scripts/hyprlock.sh"))

