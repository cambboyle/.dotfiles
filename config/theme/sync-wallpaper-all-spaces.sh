#!/usr/bin/env bash
#
# On-demand: force the currently-selected theme's wallpaper onto every
# Space, not just the one you're on. Bound to its own Raycast command
# (Sync Wallpaper to All Spaces) so it can get its own hotkey, rather than
# running automatically on every switch.
#
# Why this isn't automatic: AppleScript's `tell every desktop to set
# picture` (used in switch-theme.sh/preview-theme.sh/set-wallpaper.sh) only
# reaches whichever Space is currently visible on each display -- macOS has
# no API to set wallpaper on every Space at once. A previous attempt wrote
# straight into ~/Library/Application Support/Dock/desktoppicture.db and
# restarted the Dock, which was the standard trick pre-Sonoma -- but Apple
# dropped programmatic access to that db as of Sonoma, so it's a dead end
# on any current macOS. The only way left to actually reach every Space is
# to visit each one and apply the wallpaper while it's frontmost, which
# takes a couple of visible seconds -- too disruptive to run on every quick
# theme switch, hence its own explicit, hotkey-triggered command instead.
#
# Reads the *currently active* theme (family + light/dark mode) itself, so
# it always re-applies whatever you're already on -- no arguments needed.
#
# Usage: sync-wallpaper-all-spaces.sh
#
set -euo pipefail

# Raycast spawns child processes with a stripped-down environment that's
# missing $USER (Terminal always has it, from the login shell -- which is
# why running this script directly there worked while triggering it through
# Raycast failed with `yabai-msg: 'env USER' not set! abort..`). yabai's
# client needs $USER to find its daemon's socket, so make sure it's set
# regardless of how this script was invoked.
export USER="${USER:-$(whoami)}"

# Also silences a harmless but noisy `setlocale: LC_ALL: cannot change
# locale` warning Raycast's environment triggers (a macOS region-format
# string bash's locale support doesn't recognize) -- unrelated to the USER
# issue, just cleans up what would otherwise clutter this script's output.
export LC_ALL=C

FAMILIES="$HOME/.config/theme/families.json"
STATE_FILE="$HOME/.local/state/theme/current-family"
CHOICE_DIR="$HOME/.local/state/theme/wallpaper-choice"
WALLPAPER_DIR="$HOME/.dotfiles/config/wallpapers"

if [ ! -f "$STATE_FILE" ]; then
  echo "No current theme set yet -- switch a theme first." >&2
  exit 1
fi
FAMILY=$(cat "$STATE_FILE")

if ! jq -e --arg f "$FAMILY" 'has($f)' "$FAMILIES" >/dev/null 2>&1; then
  echo "Unknown family '$FAMILY' in families.json" >&2
  exit 1
fi

entry=$(jq -c --arg f "$FAMILY" '.[$f]' "$FAMILIES")

mode="light"
if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
  mode="dark"
fi

# Same wallpaper-resolution logic as switch-theme.sh: prefer whichever
# wallpaper was last picked for this family+mode, falling back to the
# array's default (first) entry.
wallpapers=$(jq -r --arg m "wallpapers_$mode" '.[$m] // [] | join("\n")' <<<"$entry")
default_wp=$(head -n1 <<<"$wallpapers")
choice_file="$CHOICE_DIR/${FAMILY}-${mode}"
chosen="$default_wp"
if [ -f "$choice_file" ]; then
  saved=$(cat "$choice_file")
  if grep -qxF "$saved" <<<"$wallpapers"; then
    chosen="$saved"
  fi
fi

if [ -z "$chosen" ] || [ ! -f "$WALLPAPER_DIR/$chosen" ]; then
  echo "No wallpaper resolved for $FAMILY ($mode)" >&2
  exit 1
fi
IMAGE="$WALLPAPER_DIR/$chosen"

if ! command -v yabai >/dev/null 2>&1; then
  echo "yabai not found -- can't enumerate/visit Spaces" >&2
  exit 1
fi

original_space=$(yabai -m query --spaces --space | jq -r '.index')

mapfile -t space_indices < <(yabai -m query --spaces | jq -r '.[].index')

for idx in "${space_indices[@]}"; do
  yabai -m space --focus "$idx" >/dev/null 2>&1 || continue
  # yabai's focus change and macOS actually finishing the switch aren't
  # perfectly synchronous -- give it a beat so System Events reliably sees
  # the right Space as "the" desktop for this display before we write to
  # it, rather than racing and occasionally missing one.
  sleep 0.15
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$IMAGE\"" >/dev/null 2>&1 || true
done

yabai -m space --focus "$original_space" >/dev/null 2>&1 || true

echo "==> Wallpaper synced to all spaces ($FAMILY, $mode)."
