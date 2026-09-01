#!/usr/bin/env bash
#
# Cycles to the next theme family in families.json, in order. Bash-3.2-safe
# (no mapfile) since macOS ships an old system bash by default.
#
set -euo pipefail

FAMILIES_FILE="$HOME/.config/theme/families.json"
STATE_FILE="$HOME/.local/state/theme/current-family"
SWITCH="$HOME/.config/theme/switch-theme.sh"

names=()
while IFS= read -r line; do
  names+=("$line")
done < <(jq -r 'keys[]' "$FAMILIES_FILE")

current="$(cat "$STATE_FILE" 2>/dev/null || true)"
[ -z "$current" ] && current="${names[0]}"

next=""
for i in "${!names[@]}"; do
  if [ "${names[$i]}" = "$current" ]; then
    idx=$(( (i + 1) % ${#names[@]} ))
    next="${names[$idx]}"
    break
  fi
done
[ -z "$next" ] && next="${names[0]}"

"$SWITCH" "$next"
