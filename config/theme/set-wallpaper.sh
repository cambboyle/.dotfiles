#!/usr/bin/env bash
#
# Sets one specific wallpaper for a theme family + mode, and remembers the
# choice so switch-theme.sh / toggle-light-dark.sh keep using it instead of
# the family's default wallpaper. Called by the Raycast "Browse Wallpapers"
# command -- not meant to be bound to a key directly.
#
# Usage: set-wallpaper.sh <family> <mode:dark|light> <filename>
#   e.g. set-wallpaper.sh nord dark nord-dark-3.jpg
#
set -euo pipefail

FAMILY="${1:-}"
MODE="${2:-}"
FILENAME="${3:-}"
FAMILIES="$HOME/.config/theme/families.json"
WALLPAPER_DIR="$HOME/.dotfiles/config/wallpapers"
CHOICE_DIR="$HOME/.local/state/theme/wallpaper-choice"

if [ -z "$FAMILY" ] || [ -z "$MODE" ] || [ -z "$FILENAME" ]; then
  echo "Usage: set-wallpaper.sh <family> <dark|light> <filename>"
  exit 1
fi

if [ "$MODE" != "dark" ] && [ "$MODE" != "light" ]; then
  echo "Mode must be 'dark' or 'light'"
  exit 1
fi

valid=$(jq -r --arg f "$FAMILY" --arg m "wallpapers_$MODE" --arg fn "$FILENAME" \
  '.[$f][$m] // [] | index($fn) != null' "$FAMILIES" 2>/dev/null || echo "false")
if [ "$valid" != "true" ]; then
  echo "Error: $FILENAME is not one of $FAMILY's $MODE wallpapers." >&2
  exit 1
fi

wp="$WALLPAPER_DIR/$FILENAME"
if [ ! -f "$wp" ]; then
  echo "Error: $wp not found." >&2
  exit 1
fi

mkdir -p "$CHOICE_DIR"
echo "$FILENAME" > "$CHOICE_DIR/${FAMILY}-${MODE}"

osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wp\"" >/dev/null 2>&1 || true

if [ "${THEME_SWITCH_QUIET:-0}" != "1" ]; then
  display_name=$(jq -r --arg f "$FAMILY" '.[$f].display_name' "$FAMILIES")
  osascript -e "display notification \"$FILENAME\" with title \"Wallpaper: $display_name\"" >/dev/null 2>&1 || true
fi

echo "==> Set $FAMILY/$MODE wallpaper to $FILENAME."
