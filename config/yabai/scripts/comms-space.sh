#!/usr/bin/env bash
# Re-targets the "comms" rule (Slack, Mail) to space 5 when it exists —
# i.e. your second external monitor is connected — otherwise back to
# space 3. Run on display_added / display_removed.
#
# Note: this assumes space 5 specifically is always "the comms monitor".
# If your two externals ever connect in a different order and space 5
# ends up being the other screen, this will follow the space number, not
# the physical monitor.

if yabai -m query --spaces | jq -e 'any(.[]; .index == 5)' >/dev/null 2>&1; then
  TARGET=5
else
  TARGET=3
fi

yabai -m rule --remove comms >/dev/null 2>&1
yabai -m rule --add label=comms app="^(Slack|Mail)$" space="$TARGET"

# Re-home already-open windows -- a rule only places a window at launch
# time, not retroactively. enforce-spaces.sh does this same monitor check
# itself and handles Slack (plus Zoom/Spotify/Surfshark, harmless no-ops
# here) in one place instead of duplicating the logic.
"$HOME/.config/yabai/scripts/enforce-spaces.sh"
