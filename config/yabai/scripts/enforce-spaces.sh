#!/usr/bin/env bash
# Re-homes windows for apps whose space/float placement can lose a race
# against macOS's "reopen windows at login/wake" restore. A yabai
# `space=`/`manage=off` rule only applies at window-creation time -- if a
# burst of app relaunches during that restore beats yabai's rules being
# fully (re)loaded, the window lands wherever happened to be active
# (usually space 1) and, per the note that used to live in
# comms-space.sh, a rule never retroactively fixes an already-placed
# window. This script does that fix-up instead, and is idempotent -- safe
# to run any time.
#
# Wired to run automatically both shortly after yabai (re)starts (see the
# bottom of yabairc) and whenever one of these apps (re)launches (see the
# application_launched signal in yabairc), which between them cover both
# a fresh login/wake restore and a normal manual launch.

set -uo pipefail

# Mirrors comms-space.sh's own monitor check -- Slack/Mail follow the
# second external monitor (space 5) when it's connected, space 3 otherwise.
if yabai -m query --spaces 2>/dev/null | jq -e 'any(.[]; .index == 5)' >/dev/null 2>&1; then
  comms_space=5
else
  comms_space=3
fi

move() {
  local app="$1" space="$2" wantfloat="${3:-0}"
  yabai -m query --windows 2>/dev/null | jq -c --arg app "$app" '.[] | select(.app == $app)' 2>/dev/null |
  while read -r win; do
    wid=$(jq -r '.id' <<<"$win")
    isfloat=$(jq -r '."is-floating"' <<<"$win")
    if [ "$wantfloat" = "1" ] && [ "$isfloat" != "true" ]; then
      yabai -m window "$wid" --toggle float >/dev/null 2>&1
    fi
    yabai -m window "$wid" --space "$space" >/dev/null 2>&1
  done
}

move "Slack"     "$comms_space" 0
# zoom.us / Surfshark app names are best-guess -- verify with:
#   yabai -m query --windows | jq -r '.[].app' | sort -u
# and adjust here (and the matching rule in yabairc) if they differ.
move "zoom.us"   3              1
move "Spotify"   2              1
move "Surfshark" 2              1
