#!/usr/bin/env bash
# ~/dotfiles/scripts/show_keybinds.sh
# Parses keybinds.conf and shows a searchable cheatsheet via fuzzel

grep -E "^\s*bind" ~/.config/hypr/keybinds.conf |
  sed -E 's/^\s*bind[lme]*\s*=\s*/  /' |
  column -t -s',' |
  fuzzel --dmenu -p "Keybinds  "
