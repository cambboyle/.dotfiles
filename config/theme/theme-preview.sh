#!/usr/bin/env bash
#
# fzf --preview helper: shows the dark wallpaper for the given family using
# chafa's Kitty Graphics Protocol output, which Ghostty renders natively.
#
set -euo pipefail

FAMILIES="$HOME/.config/theme/families.json"
WALLPAPER_DIR="$HOME/.dotfiles/config/wallpapers"

family="${1:-}"
entry=$(jq -c --arg f "$family" '.[$f] // empty' "$FAMILIES")
[ -z "$entry" ] && exit 0

display_name=$(jq -r '.display_name' <<<"$entry")
wp_dark=$(jq -r '.wallpaper_dark' <<<"$entry")
ghostty_dark=$(jq -r '.ghostty_dark' <<<"$entry")
ghostty_light=$(jq -r '.ghostty_light' <<<"$entry")

echo "$display_name"
echo "Ghostty: $ghostty_dark / $ghostty_light"
echo

if command -v chafa >/dev/null 2>&1 && [ -f "$WALLPAPER_DIR/$wp_dark" ]; then
  chafa -f kitty -s 60x30 "$WALLPAPER_DIR/$wp_dark"
else
  echo "(install chafa for a live preview here: brew install chafa)"
fi
