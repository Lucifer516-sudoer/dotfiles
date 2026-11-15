local programs = {
    terminal          = "ghostty",
    file_manager      = "thunar",
    menu              = "fuzzel",
    clipboard_manager = 'sh -c "cliphist list | wofi --dmenu | cliphist decode | wl-copy"',
    hypridle          = "hypridle",
    -- caelestia_shell_daemon = "caelestia shell --daemon",
    wl_paste_text     = "wl-paste --type text --watch cliphist store",
    wl_paste_image    = "wl-paste --type image --watch cliphist store",
    kanshi            = "kanshi",
    polkit_kde        = "/usr/lib/polkit-kde-authentication-agent-1",
    swaync            = "swaync",
    waybar            = "waybar",
    awww_daemon       = "awww-daemon",
}

return programs
