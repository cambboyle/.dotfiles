#!/usr/bin/env bash
#
# Umbra replacement: flips macOS light/dark appearance, then re-applies the
# wallpaper for whichever theme family is currently selected so it follows
# along -- using whichever wallpaper you last picked for that family+mode
# (Raycast "Browse Wallpapers"), or the default (first) one otherwise.
# Ghostty and Zed already watch system appearance themselves (both
# configured with light/dark pairs), so nothing else needs poking here.
#
set -euo pipefail

osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode'

STATE_FILE="$HOME/.local/state/theme/current-family"
CHOICE_DIR="$HOME/.local/state/theme/wallpaper-choice"
WALLPAPER_DIR="$HOME/.dotfiles/config/wallpapers"
FAMILIES="$HOME/.config/theme/families.json"

if [ -f "$STATE_FILE" ] && [ -f "$FAMILIES" ]; then
  family=$(cat "$STATE_FILE")
  entry=$(jq -c --arg f "$family" '.[$f] // empty' "$FAMILIES")
  if [ -n "$entry" ]; then
    mode="light"
    defaults read -g AppleInterfaceStyle >/dev/null 2>&1 && mode="dark"

    wallpapers=$(jq -r --arg m "wallpapers_$mode" '.[$m] // [] | join("\n")' <<<"$entry")
    default_wp=$(head -n1 <<<"$wallpapers")
    choice_file="$CHOICE_DIR/${family}-${mode}"
    chosen="$default_wp"
    if [ -f "$choice_file" ]; then
      saved=$(cat "$choice_file")
      if grep -qxF "$saved" <<<"$wallpapers"; then
        chosen="$saved"
      fi
    fi

    if [ -n "$chosen" ] && [ -f "$WALLPAPER_DIR/$chosen" ]; then
      osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$WALLPAPER_DIR/$chosen\"" >/dev/null 2>&1 || true
    fi

    display_name=$(jq -r '.display_name' <<<"$entry")
    mode_label="Dark"
    [ "$mode" = "light" ] && mode_label="Light"
    osascript -e "display notification \"$mode_label mode\" with title \"Theme: $display_name\"" >/dev/null 2>&1 || true
  fi
fi
