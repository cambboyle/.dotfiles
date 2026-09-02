#!/usr/bin/env bash
#
# Switches the active "theme family" (23 of them now -- see families.json
# for the full list) across Ghostty, Zed, borders, btop, Starship, and the
# desktop wallpaper. Light vs dark within the family is read from macOS's
# current appearance setting -- use toggle-light-dark.sh to flip that
# (bound in skhd), or this still resolves correctly if you flip it via
# System Settings directly.
#
# Starship's config lives at ~/.dotfiles/config/starship/starship.toml.tpl
# (a template) -> apply-starship-theme.py renders it into the real
# ~/.dotfiles/config/starship/starship.toml, which ~/.config/starship.toml
# symlinks to -- same "dotfiles is the source of truth, ~/.config just
# points at it" setup as Ghostty. No reload needed; starship just reads
# its config fresh on every prompt.
#
# LazyVim (Neovim) also follows along, but not from here -- its
# colorscheme.lua reads the current family/mode itself at Neovim startup
# (see that file), so there's nothing for this script to write. Just means
# a theme picked up by Neovim needs a fresh `nvim` to show.
#
# Each family now ships 5-6 wallpapers per mode (wallpapers_dark /
# wallpapers_light arrays in families.json) instead of just one. This picks
# whichever one you last chose for that family+mode via the Raycast
# "Change Wallpaper..." action (persisted in
# ~/.local/state/theme/wallpaper-choice/), falling back to the first
# (default) wallpaper in the array if you've never picked one.
#
# Usage: switch-theme.sh <family>   e.g. switch-theme.sh nord
#
set -euo pipefail

FAMILY="${1:-}"
FAMILIES="$HOME/.config/theme/families.json"
STATE_DIR="$HOME/.local/state/theme"
STATE_FILE="$STATE_DIR/current-family"
CHOICE_DIR="$STATE_DIR/wallpaper-choice"
WALLPAPER_DIR="$HOME/.dotfiles/config/wallpapers"
# Edit the real dotfiles-managed file directly, not the ~/.config/ghostty/config
# symlink that points to it -- `sed -i` replaces whatever's at its target
# path rather than writing through a symlink, which would silently turn
# that symlink into a disconnected plain file on the very first switch.
# Writing the real file keeps the symlink (and Ghostty, which reads
# through it) correctly wired with no extra step.
GHOSTTY_CONF="$HOME/.dotfiles/config/ghostty/config.ghostty"
ZED_SETTINGS="$HOME/.config/zed/settings.json"
BORDERS_CONF="$HOME/.config/borders/bordersrc"

if [ -z "$FAMILY" ] || ! jq -e --arg f "$FAMILY" 'has($f)' "$FAMILIES" >/dev/null 2>&1; then
  echo "Usage: switch-theme.sh <family>"
  echo "Available: $(jq -r 'keys | join(", ")' "$FAMILIES")"
  exit 1
fi

entry=$(jq -c --arg f "$FAMILY" '.[$f]' "$FAMILIES")
ghostty_dark=$(jq -r '.ghostty_dark' <<<"$entry")
ghostty_light=$(jq -r '.ghostty_light' <<<"$entry")
zed_dark=$(jq -r '.zed_dark' <<<"$entry")
zed_light=$(jq -r '.zed_light' <<<"$entry")
borders_active=$(jq -r '.borders_active' <<<"$entry")
borders_inactive=$(jq -r '.borders_inactive' <<<"$entry")

mkdir -p "$STATE_DIR" "$CHOICE_DIR"
echo "$FAMILY" > "$STATE_FILE"

# Every family entry now has a fixed single_mode (light/dark split families
# and the naturally single-mode ones alike) -- use that directly instead of
# reading macOS's current appearance, and then force macOS to actually
# match it: disable "automatically switch appearance" (it would otherwise
# silently flip you back at sunset/sunrise) and set dark/light mode
# explicitly via System Events, which applies instantly with no restart.
# This is what makes "the theme decides light/dark" stick, including
# across reboots -- macOS's appearance setting persists on its own once
# set, so there's nothing extra needed for "on launch".
single_mode=$(jq -r '.single_mode // empty' <<<"$entry")
if [ -n "$single_mode" ]; then
  mode="$single_mode"
  defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false 2>/dev/null || true
  if [ "$mode" = "dark" ]; then
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' >/dev/null 2>&1 || true
  else
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' >/dev/null 2>&1 || true
  fi
else
  # Fallback for any entry that somehow has no single_mode -- read macOS's
  # current appearance instead, same as before this was added.
  mode="light"
  if defaults read -g AppleInterfaceStyle >/dev/null 2>&1; then
    mode="dark"
  fi
fi

# -- Ghostty: replace every theme= line (active or commented-out -- past
# switches/manual experiments can leave several stacked up, and if the
# *active* one ever ends up commented, a plain sed replace on "^theme="
# silently matches nothing and leaves Ghostty on no theme at all, which is
# exactly what happened) with exactly one fresh, uncommented line. Keeps
# the dark:/light: pairing so it keeps auto-following macOS appearance.
if [ -f "$GHOSTTY_CONF" ]; then
  awk -v new="theme= dark:${ghostty_dark},light:${ghostty_light}" '
    BEGIN { inserted=0 }
    /^[[:space:]]*#?[[:space:]]*theme=/ { next }
    /^# aesthetics/ && !inserted { print; print new; inserted=1; next }
    { print }
    END { if (!inserted) print new }
  ' "$GHOSTTY_CONF" > "$GHOSTTY_CONF.new" && mv "$GHOSTTY_CONF.new" "$GHOSTTY_CONF"
  if pgrep -x Ghostty >/dev/null 2>&1; then
    # Trigger reload_config via Ghostty's native AppleScript support
    # (perform action "..." on a terminal object) instead of simulating the
    # cmd+shift+, keystroke -- that keystroke sim was the reason live
    # updates never worked: Ghostty has a known issue (ghostty-org/ghostty
    # discussions #3241) where rapid synthetic multi-modifier keystrokes
    # can get misread as the plain cmd+, binding, which just opens the
    # config file instead of reloading it. This goes straight to the named
    # action, no keyboard/timing involved. Chained with clear_screen since
    # reload_config alone doesn't repaint text already on screen -- see
    # ghostty-org/ghostty issue #1141 -- only new output picks up the new
    # palette otherwise; clear_screen forces an immediate repaint of the
    # visible viewport (like Ctrl+L, scrollback untouched).
    osascript \
      -e 'tell application "Ghostty"' \
      -e 'set t to focused terminal of selected tab of front window' \
      -e 'perform action "reload_config" on t' \
      -e 'perform action "clear_screen" on t' \
      -e 'end tell' \
      >/dev/null 2>&1 || true
  fi
fi

# -- Zed: replace just the theme block. See apply-zed-theme.py for why
# this is a targeted regex swap (JSON5 trailing commas, jq can't
# round-trip it) done via an atomic write rather than an in-place one. --
if [ "$zed_dark" != "null" ] && [ -f "$ZED_SETTINGS" ]; then
  python3 "$HOME/.config/theme/apply-zed-theme.py" "$ZED_SETTINGS" "$zed_light" "$zed_dark"
else
  echo "note: no Zed theme configured yet for '$FAMILY' -- Zed left as-is (needs its theme extension installed first)."
fi

# -- borders --
if [ -f "$BORDERS_CONF" ]; then
  sed -i.bak -E "s/active_color=0x[0-9a-fA-F]{8}/active_color=${borders_active}/; s/inactive_color=0x[0-9a-fA-F]{8}/inactive_color=${borders_inactive}/" "$BORDERS_CONF"
  rm -f "$BORDERS_CONF.bak"

  # Pull the full current option set back out of bordersrc (not just the
  # two colors just changed) so the live update below doesn't clobber any
  # style/width/hidpi customization made directly in that file.
  border_opts=()
  while IFS= read -r line; do
    border_opts+=("$line")
  done < <(grep -E '^[[:space:]]*(style|width|hidpi|active_color|inactive_color)=' "$BORDERS_CONF" | sed -E 's/^[[:space:]]+//')

  BORDERS_BIN="$(command -v borders || echo /opt/homebrew/bin/borders)"
  # JankyBorders runs as a single persistent instance -- invoking `borders`
  # again with new options forwards them to the already-running instance
  # over its own IPC and returns almost instantly, no daemon restart
  # needed. This replaces `brew services restart`, which was the slowest
  # part of both live preview and a real switch (launchd fully stopping
  # and relaunching the process, ~1-2s every time). Falls back to the old
  # restart if the live update fails for any reason, so this can't leave
  # borders in a broken state.
  if [ ${#border_opts[@]} -gt 0 ]; then
    "$BORDERS_BIN" "${border_opts[@]}" >/dev/null 2>&1 || \
      brew services restart FelixKratz/formulae/borders >/dev/null 2>&1 || true
  else
    brew services restart FelixKratz/formulae/borders >/dev/null 2>&1 || true
  fi
fi

# -- btop: make sure its config points at our generated theme (a one-line
# patch if btop.conf already exists, or a fresh copy of btop's own stock
# default -- with that line already set -- if it doesn't), then render the
# theme from this family's palette and nudge any running btop to reload it
# live. See apply-btop-theme.py for the reload mechanism. --
BTOP_CONF="$HOME/.config/btop/btop.conf"
BTOP_CONF_DEFAULT="$HOME/.dotfiles/config/btop/btop.conf.default"
if [ -f "$BTOP_CONF" ]; then
  if grep -q '^color_theme' "$BTOP_CONF"; then
    sed -i.bak -E 's/^color_theme[[:space:]]*=.*/color_theme = "current"/' "$BTOP_CONF"
    rm -f "$BTOP_CONF.bak"
  else
    printf '\ncolor_theme = "current"\n' >> "$BTOP_CONF"
  fi
elif [ -f "$BTOP_CONF_DEFAULT" ]; then
  mkdir -p "$HOME/.config/btop"
  cp "$BTOP_CONF_DEFAULT" "$BTOP_CONF"
fi
python3 "$HOME/.config/theme/apply-btop-theme.py" "$FAMILY" "$mode"

# -- starship: render the prompt from this family's palette. No reload
# needed -- starship reads its config file fresh on every prompt render,
# so the next prompt just picks it up. --
python3 "$HOME/.config/theme/apply-starship-theme.py" "$FAMILY" "$mode"

# -- wallpaper: sync-wallpaper-all-spaces.sh resolves which wallpaper to
# use itself (same rule as below -- prefers whichever you last picked for
# this family+mode via Raycast "Change Wallpaper...", falling back to the
# array's default) and applies it to every Space by briefly visiting each
# one in turn, since macOS has no API to set wallpaper on every Space at
# once (a prior attempt writing straight into the per-space wallpaper db
# worked pre-Sonoma but is a dead end on any current macOS). It reads
# $STATE_FILE, which is already updated to $FAMILY above, so it always
# picks up the theme being switched *to*. Only wired in here (a real
# switch) -- preview-theme.sh deliberately stays on the single quick
# "current desktop" osascript call instead, since cycling every Space on
# every arrow-key move while browsing themes would be far too janky.
"$HOME/.config/theme/sync-wallpaper-all-spaces.sh" || true

if [ "${THEME_SWITCH_QUIET:-0}" != "1" ]; then
  display_name=$(jq -r '.display_name' <<<"$entry")
  mode_label="Dark"
  [ "$mode" = "light" ] && mode_label="Light"
  osascript -e "display notification \"$mode_label mode\" with title \"Theme: $display_name\"" >/dev/null 2>&1 || true
fi

echo "==> Switched to $FAMILY ($mode)."
