#!/usr/bin/env bash
#
# Omarchy/rice-picker-style theme selector: arrow through families, see the
# wallpaper live in the preview pane, hit enter to apply. Meant to be run
# inside its own Ghostty window (bound in skhd via `ghostty -e`).
#
set -euo pipefail

FAMILIES="$HOME/.config/theme/families.json"
SWITCH="$HOME/.config/theme/switch-theme.sh"
PREVIEW="$HOME/.config/theme/theme-preview.sh"

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf not found -- brew install fzf"
  read -n 1 -s -r -p "press any key to close..."
  exit 1
fi

selected=$(jq -r 'keys[]' "$FAMILIES" | fzf \
  --prompt="theme > " \
  --header="enter: apply   esc: cancel" \
  --preview="$PREVIEW {}" \
  --preview-window=right:65%)

if [ -n "$selected" ]; then
  "$SWITCH" "$selected"
  echo
  read -n 1 -s -r -p "applied. press any key to close..."
fi
