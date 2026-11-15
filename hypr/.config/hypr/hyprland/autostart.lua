local programs = require("hyprland.programs");

hl.on("hyprland.start", function()
    -- hl.exec_cmd(programs.caelestia_shell_daemon);
    -- hl.exec_cmd(programs.clipboard_manager);
    hl.exec_cmd(programs.file_manager);
    hl.exec_cmd(programs.hypridle);
    hl.exec_cmd(programs.kanshi);
    hl.exec_cmd(programs.polkit_kde);
    hl.exec_cmd(programs.swaync);
    -- hl.exec_cmd(programs.terminal);
    hl.exec_cmd(programs.wl_paste_image);
    hl.exec_cmd(programs.wl_paste_text);
    hl.exec_cmd(programs.awww_daemon);
    hl.exec_cmd(programs.waybar);
end)
