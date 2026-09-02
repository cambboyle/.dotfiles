#!/usr/bin/env bash
#
# Live-preview variant of switch-theme.sh, called on every arrow-key move in
# the Raycast "Switch Theme" picker so you can see the real look before
# committing. Applies wallpaper + Ghostty + Zed + borders + btop + Starship
# exactly like switch-theme.sh (LazyVim is excluded from both -- see
# colorscheme.lua, which reads the current family/mode itself at Neovim
# startup instead of being written to), but deliberately skips two things a
# mid-browse preview shouldn't touch:
#   - ~/.local/state/theme/current-family (so merely arrowing through the
#     list never changes what toggle-light-dark.sh / cycle-family.sh think
#     is "current" -- only pressing Enter does that, via switch-theme.sh)
#   - notifications (arrowing quickly would otherwise spam them)
#
# Zed's theme write goes through apply-zed-theme.py, which writes via a
# temp-file + atomic rename and skips the write entirely if the theme
# would come out unchanged -- safe to call on every preview tick without
# risking a half-written settings.json if Zed happens to read at the same
# moment (see that script for details).
#
# Raycast also calls this with the *original* family to restore your look
# if you back out of the picker without picking anything.
#
# Usage: preview-theme.sh <family>
#
set -euo pipefail

FAMILY="${1:-}"
FAMILIES="$HOME/.config/theme/families.json"
CHOICE_DIR="$HOME/.local/state/theme/wallpaper-choice"
WALLPAPER_DIR="$HOME/.dotfiles/config/wallpapers"
# See switch-theme.sh for why this targets the real dotfiles file rather
# than the ~/.config/ghostty/config symlink pointing to it.
GHOSTTY_CONF="$HOME/.dotfiles/config/ghostty/config.ghostty"
ZED_SETTINGS="$HOME/.config/zed/settings.json"
BORDERS_CONF="$HOME/.config/borders/bordersrc"

if [ -z "$FAMILY" ] || ! jq -e --arg f "$FAMILY" 'has($f)' "$FAMILIES" >/dev/null 2>&1; then
  exit 0
fi

entry=$(jq -c --arg f "$FAMILY" '.[$f]' "$FAMILIES")
ghostty_dark=$(jq -r '.ghostty_dark' <<<"$entry")
ghostty_light=$(jq -r '.ghostty_light' <<<"$entry")
zed_dark=$(jq -r '.zed_dark' <<<"$entry")
zed_light=$(jq -r '.zed_light' <<<"$entry")
borders_active=$(jq -r '.borders_active' <<<"$entry")
borders_inactive=$(jq -r '.borders_inactive' <<<"$entry")

# Use the entry's own fixed single_mode (see switch-theme.sh) when it has
# one, same as a real switch -- but deliberately don't force macOS's actual
# appearance here, only there: flipping the whole system light/dark on
# every arrow-key move while browsing themes would be far too jarring.
# Falls back to reading macOS's current appearance for any entry without a
# single_mode.
single_mode=$(jq -r '.single_mode // empty' <<<"$entry")
if [ -n "$single_mode" ]; then
  mode="$single_mode"
else
  mode="light"
  if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
    mode="dark"
  fi
fi

# See switch-theme.sh for why this replaces every theme= line (active or
# commented-out) rather than sed-substituting just the active one.
if [ -f "$GHOSTTY_CONF" ]; then
  awk -v new="theme= dark:${ghostty_dark},light:${ghostty_light}" '
    BEGIN { inserted=0 }
    /^[[:space:]]*#?[[:space:]]*theme=/ { next }
    /^# aesthetics/ && !inserted { print; print new; inserted=1; next }
    { print }
    END { if (!inserted) print new }
  ' "$GHOSTTY_CONF" > "$GHOSTTY_CONF.new" && mv "$GHOSTTY_CONF.new" "$GHOSTTY_CONF"
  if pgrep -x Ghostty >/dev/null 2>&1; then
    # See switch-theme.sh for why this uses Ghostty's native AppleScript
    # "perform action" instead of a simulated cmd+shift+, keystroke, and why
    # it's chained with clear_screen (reload_config alone doesn't repaint
    # text already on screen).
    osascript \
      -e 'tell application "Ghostty"' \
      -e 'set t to focused terminal of selected tab of front window' \
      -e 'perform action "reload_config" on t' \
      -e 'perform action "clear_screen" on t' \
      -e 'end tell' \
      >/dev/null 2>&1 || true
  fi
fi

if [ "$zed_dark" != "null" ] && [ -f "$ZED_SETTINGS" ]; then
  python3 "$HOME/.config/theme/apply-zed-theme.py" "$ZED_SETTINGS" "$zed_light" "$zed_dark"
fi

if [ -f "$BORDERS_CONF" ]; then
  sed -i.bak -E "s/active_color=0x[0-9a-fA-F]{8}/active_color=${borders_active}/; s/inactive_color=0x[0-9a-fA-F]{8}/inactive_color=${borders_inactive}/" "$BORDERS_CONF"
  rm -f "$BORDERS_CONF.bak"

  # See switch-theme.sh: JankyBorders forwards new options to its already-
  # running instance instead of needing a full daemon restart, which is
  # what made both preview and a real switch feel sluggish before.
  border_opts=()
  while IFS= read -r line; do
    border_opts+=("$line")
  done < <(grep -E '^[[:space:]]*(style|width|hidpi|active_color|inactive_color)=' "$BORDERS_CONF" | sed -E 's/^[[:space:]]+//')

  BORDERS_BIN="$(command -v borders || echo /opt/homebrew/bin/borders)"
  if [ ${#border_opts[@]} -gt 0 ]; then
    "$BORDERS_BIN" "${border_opts[@]}" >/dev/null 2>&1 || \
      brew services restart FelixKratz/formulae/borders >/dev/null 2>&1 || true
  else
    brew services restart FelixKratz/formulae/borders >/dev/null 2>&1 || true
  fi
fi

# btop reloads live via SIGUSR2 (see apply-btop-theme.py), so it's cheap
# and safe to include on every preview tick, same as the others above.
python3 "$HOME/.config/theme/apply-btop-theme.py" "$FAMILY" "$mode"

# starship needs no reload signal either -- it just reads its config file
# fresh on every prompt render -- so it's just as safe to include here.
python3 "$HOME/.config/theme/apply-starship-theme.py" "$FAMILY" "$mode"

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

if [ -n "$chosen" ] && [ -f "$WALLPAPER_DIR/$chosen" ]; then
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$WALLPAPER_DIR/$chosen\"" >/dev/null 2>&1 || true
fi
