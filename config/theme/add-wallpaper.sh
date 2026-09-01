#!/usr/bin/env bash
#
# Downloads (or copies) an image and adds it to a theme family's wallpaper
# picker: normalizes it to a reasonably-sized JPEG, drops it into
# ~/.dotfiles/config/wallpapers alongside the curated set, mirrors it into
# the Raycast extension's bundled assets (needed for the in-picker preview),
# and appends it to that family+mode's array in families.json. Called by
# the Raycast "Discover More Wallpapers" view -- not meant to be run by hand
# day-to-day, though it works fine that way too.
#
# Usage: add-wallpaper.sh <family> <dark|light> <url-or-local-path>
#
set -euo pipefail

FAMILY="${1:-}"
MODE="${2:-}"
SOURCE="${3:-}"

FAMILIES="$HOME/.config/theme/families.json"
WALLPAPER_DIR="$HOME/.dotfiles/config/wallpapers"
RAYCAST_ASSETS_DIR="$HOME/.dotfiles/config/raycast-theme-switcher/assets/wallpapers"

if [ -z "$FAMILY" ] || [ -z "$MODE" ] || [ -z "$SOURCE" ]; then
  echo "Usage: add-wallpaper.sh <family> <dark|light> <url-or-local-path>" >&2
  exit 1
fi
if [ "$MODE" != "dark" ] && [ "$MODE" != "light" ]; then
  echo "Error: mode must be 'dark' or 'light'" >&2
  exit 1
fi
if ! jq -e --arg f "$FAMILY" 'has($f)' "$FAMILIES" >/dev/null 2>&1; then
  echo "Error: unknown family '$FAMILY'" >&2
  exit 1
fi

tmp_download=""
cleanup() { [ -n "$tmp_download" ] && rm -f "$tmp_download"; }
trap cleanup EXIT

if [[ "$SOURCE" =~ ^https?:// ]]; then
  tmp_download="$(mktemp -t wallpaper-download)"
  if ! curl -fsSL --max-time 30 "$SOURCE" -o "$tmp_download"; then
    echo "Error: download failed for $SOURCE" >&2
    exit 1
  fi
  src_file="$tmp_download"
else
  src_file="$SOURCE"
fi

if [ ! -s "$src_file" ]; then
  echo "Error: source image is missing or empty." >&2
  exit 1
fi

existing_count=$(jq -r --arg f "$FAMILY" --arg m "wallpapers_$MODE" '.[$f][$m] // [] | length' "$FAMILIES")
next=$((existing_count + 1))
target_name="${FAMILY}-${MODE}-${next}.jpg"

mkdir -p "$WALLPAPER_DIR" "$RAYCAST_ASSETS_DIR"

# Normalize to JPEG, cap the long edge at 3200px -- sips is built into
# macOS so this needs nothing extra installed.
if ! sips -s format jpeg -s formatOptions 88 -Z 3200 "$src_file" --out "$WALLPAPER_DIR/$target_name" >/dev/null 2>&1; then
  echo "Error: sips couldn't process that image (unsupported format?)." >&2
  exit 1
fi

cp "$WALLPAPER_DIR/$target_name" "$RAYCAST_ASSETS_DIR/$target_name"

tmp_json=$(mktemp)
jq --arg f "$FAMILY" --arg m "wallpapers_$MODE" --arg fn "$target_name" \
  '.[$f][$m] += [$fn]' "$FAMILIES" > "$tmp_json" && mv "$tmp_json" "$FAMILIES"

echo "$target_name"
