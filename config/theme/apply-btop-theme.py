#!/usr/bin/env python3
#
# Renders btop's current.theme from families.json's palette_<mode> for the
# given family, substituting {{ field }} placeholders in btop.theme.tpl.
# That template is Omarchy's own (github.com/basecamp/omarchy, default/
# themed/btop.theme.tpl) reused as-is -- our palette fields were built to
# match its field names exactly, so no adaptation was needed.
#
# Writes via a temp-file + atomic rename (same reasoning as
# apply-zed-theme.py) and skips entirely if the rendered theme is
# unchanged. Then nudges any running btop to reload live with SIGUSR2 --
# btop watches specifically for that signal to reload its config/theme, no
# restart needed. This is the exact mechanism Omarchy's own theme switcher
# uses (bin/omarchy-restart-btop: `pkill -SIGUSR2 btop`).
#
# Usage: apply-btop-theme.py <family> <dark|light>
#
import json
import os
import re
import signal
import subprocess
import sys
import tempfile

FAMILIES_PATH = os.path.expanduser("~/.config/theme/families.json")
TEMPLATE_PATH = os.path.expanduser("~/.dotfiles/config/btop/btop.theme.tpl")
THEMES_DIR = os.path.expanduser("~/.config/btop/themes")
TARGET_PATH = os.path.join(THEMES_DIR, "current.theme")


def reload_running_btop():
    try:
        result = subprocess.run(["pgrep", "-x", "btop"], capture_output=True, text=True)
    except OSError:
        return
    for pid in result.stdout.split():
        try:
            os.kill(int(pid), signal.SIGUSR2)
        except (ValueError, ProcessLookupError):
            pass


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in ("dark", "light"):
        print("Usage: apply-btop-theme.py <family> <dark|light>", file=sys.stderr)
        return 1
    family, mode = sys.argv[1], sys.argv[2]

    try:
        with open(FAMILIES_PATH) as f:
            families = json.load(f)
        with open(TEMPLATE_PATH) as f:
            template = f.read()
    except OSError as e:
        print(f"warning: {e}", file=sys.stderr)
        return 0  # best-effort, like the other theme scripts

    palette = families.get(family, {}).get(f"palette_{mode}")
    if not palette:
        print(f"warning: no palette_{mode} for family '{family}', skipped btop", file=sys.stderr)
        return 0

    def substitute(m):
        key = m.group(1).strip()
        return palette.get(key, m.group(0))

    rendered = re.sub(r"\{\{\s*([a-zA-Z_]+)\s*\}\}", substitute, template)

    try:
        with open(TARGET_PATH) as f:
            if f.read() == rendered:
                return 0  # already on this theme -- nothing to write or reload
    except OSError:
        pass  # doesn't exist yet -- fall through and create it

    os.makedirs(THEMES_DIR, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(dir=THEMES_DIR, prefix=".current-", suffix=".theme.tmp")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(rendered)
        os.replace(tmp_path, TARGET_PATH)
    except OSError as e:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        print(f"warning: couldn't write {TARGET_PATH}: {e}", file=sys.stderr)
        return 0

    reload_running_btop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
