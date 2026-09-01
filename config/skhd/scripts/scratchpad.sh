#!/usr/bin/env bash
#
# Quake-style scratchpad terminal. Press the bind once: Ghostty appears as a
# floating, centered window. Press it again while Ghostty is frontmost: it
# hides (not minimizes) instead of closing, so your session/shell state is
# preserved for next time.
#
set -euo pipefail

APP="Ghostty"

FRONTMOST=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null || true)

if [ "$FRONTMOST" = "$APP" ]; then
  osascript -e "tell application \"System Events\" to set visible of process \"$APP\" to false"
  exit 0
fi

open -a "$APP"

# wait for the window to exist (launch isn't instant the first time)
WID=""
for _ in 1 2 3 4 5 6 7 8 9 10; do
  WID=$(yabai -m query --windows --app "$APP" 2>/dev/null | jq -r 'sort_by(.id) | last | .id // empty')
  [ -n "$WID" ] && break
  sleep 0.05
done

if [ -n "$WID" ]; then
  IS_FLOATING=$(yabai -m query --windows --window "$WID" | jq -r '."is-floating"')
  if [ "$IS_FLOATING" != "true" ]; then
    yabai -m window "$WID" --toggle float
  fi
  yabai -m window "$WID" --grid 10:10:1:1:8:6
  yabai -m window "$WID" --focus
fi

osascript -e "tell application \"System Events\" to set visible of process \"$APP\" to true"
