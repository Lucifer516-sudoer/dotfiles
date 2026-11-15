Whats needed to update:
- [x] [hyprland.lua](hyprland.lua)
- [x] [autostart.lua](./hyprland/autostart.lua)
- [x] [env.lua](./hyprland/env.lua)
- [x] [inputs.lua](./hyprland/inputs.lua)
- [x] [keybinds.lua](./hyprland/keybinds.lua)
- [x] [monitors.lua](./hyprland/monitors.lua)
- [x] [programs.lua](./hyprland/programs.lua)
- [ ] [variables.lua](./hyprland/variables.lua)
- [ ] [window_rules.lua](./hyprland/window_rules.lua)
- [ ] [workspace.lua](./hyprland/workspace.lua)


# 4th August, 2026 - 8:37:42 PM
- Up until now, have updated the following:
  - [hyprland.lua](hyprland.lua)
  - [autostart.lua](./hyprland/autostart.lua)
  - [env.lua](./hyprland/env.lua)
  - [inputs.lua](./hyprland/inputs.lua)
  - [keybinds.lua](./hyprland/keybinds.lua)
  - [monitors.lua](./hyprland/monitors.lua)
  - [programs.lua](./hyprland/programs.lua)

---


# 4th August, 2026 - 10:48:45 PM
Feeling sleepy, practiced mocking sort of thing with chatgpt


---

# 6th August, 2026 - 11:30:00 AM

- Refactored `hyprland.lua` to be module-first and removed duplicated
  `input`, `monitor` and `keybind` sections in favor of the files under
  `./hyprland/`.
- Authoritative files now:
  - `./hyprland/inputs.lua`
  - `./hyprland/monitors.lua`
  - `./hyprland/keybinds.lua`
  - `./hyprland/programs.lua`

Notes:
- `hyprland.lua` now contains global settings and window/workspace rules
  only. Modular files are required at the top of `hyprland.lua` so they are
  loaded automatically.