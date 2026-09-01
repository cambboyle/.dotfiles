#!/usr/bin/env bash
# Centers the focused window at ~60% of the screen. Floats it first if it
# isn't already floating (tiled windows use tree-relative --grid coords).
IS_FLOATING=$(yabai -m query --windows --window | jq -r '."is-floating"')
if [ "$IS_FLOATING" != "true" ]; then
  yabai -m window --toggle float
fi
yabai -m window --grid 10:10:2:2:6:6
