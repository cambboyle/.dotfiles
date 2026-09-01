#!/usr/bin/env python3
#
# Renders ~/.config/starship.toml from families.json's palette_<mode> for
# the given family, substituting {{ field }} placeholders in
# starship.toml.tpl (Cam's own hand-built Gruvbox prompt, with its 10
# hardcoded hex colors swapped for palette fields -- layout/icons/format
# untouched).
#
# Writes via a temp-file + atomic rename (same reasoning as
# apply-zed-theme.py / apply-btop-theme.py) and skips entirely if the
# rendered prompt is unchanged. No reload signal needed here, unlike
# btop/Zed -- starship just reads its config file fresh on every prompt
# render, so the very next prompt picks up the change automatically.
#
# Usage: apply-starship-theme.py <family> <dark|light>
#
import json
import os
import re
import sys
import tempfile

FAMILIES_PATH = os.path.expanduser("~/.config/theme/families.json")
TEMPLATE_PATH = os.path.expanduser("~/.dotfiles/config/starship/starship.toml.tpl")
# ~/.config/starship.toml is a symlink into the dotfiles-managed copy (see
# the starship/ setup this file lives beside). os.replace() on a symlink
# path replaces the symlink itself rather than writing through it, which
# would silently turn ~/.config/starship.toml back into a plain file and
# break that setup -- so resolve to the real file first and write there;
# the symlink is left untouched and keeps pointing at it.
TARGET_PATH = os.path.realpath(os.path.expanduser("~/.config/starship.toml"))


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in ("dark", "light"):
        print("Usage: apply-starship-theme.py <family> <dark|light>", file=sys.stderr)
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
        print(f"warning: no palette_{mode} for family '{family}', skipped starship", file=sys.stderr)
        return 0

    def substitute(m):
        key = m.group(1).strip()
        return palette.get(key, m.group(0))

    rendered = re.sub(r"\{\{\s*([a-zA-Z_]+)\s*\}\}", substitute, template)

    try:
        with open(TARGET_PATH) as f:
            if f.read() == rendered:
                return 0  # already on this theme -- nothing to write
    except OSError:
        pass  # doesn't exist yet (shouldn't happen post-symlink-setup) -- fall through

    target_dir = os.path.dirname(TARGET_PATH)
    os.makedirs(target_dir, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(dir=target_dir, prefix=".starship-", suffix=".toml.tmp")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(rendered)
        os.replace(tmp_path, TARGET_PATH)
    except OSError as e:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        print(f"warning: couldn't write {TARGET_PATH}: {e}", file=sys.stderr)
        return 0

    return 0


if __name__ == "__main__":
    sys.exit(main())
