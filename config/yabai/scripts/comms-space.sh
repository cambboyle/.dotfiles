#!/usr/bin/env bash
# Re-targets the "comms" rule (Slack, Mail) to space 6 when it exists —
# i.e. your second external monitor is connected — otherwise back to
# space 3. Run on display_added / display_removed. Also re-homes any
# Slack/Mail windows that are already open, since a rule only places a
# window at launch time, not retroactively.
#
# Note: this assumes space 6 specifically is always "the comms monitor".
# If your two externals ever connect in a different order and space 6
# ends up being the other screen, this will follow the space number, not
# the physical monitor.

if yabai -m query --spaces | jq -e 'any(.[]; .index == 6)' >/dev/null 2>&1; then
  TARGET=6
else
  TARGET=3
fi

yabai -m rule --remove comms >/dev/null 2>&1
yabai -m rule --add label=comms app="^(Slack|Mail)$" space="$TARGET"

yabai -m query --windows | jq -r '.[] | select(.app == "Slack" or .app == "Mail") | .id' | \
while read -r wid; do
  yabai -m window "$wid" --space "$TARGET" 2>/dev/null
done
