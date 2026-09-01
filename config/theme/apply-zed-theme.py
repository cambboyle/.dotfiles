#!/usr/bin/env python3
#
# Rewrites the "theme" block in Zed's settings.json (JSON5, so jq can't
# round-trip it safely -- this is a targeted regex swap that leaves the
# rest of the file untouched). Shared by switch-theme.sh (a real commit)
# and preview-theme.sh (called on every arrow-key move while browsing
# themes), so both go through the exact same safety logic:
#
#   - Skips the write entirely if the theme block would come out
#     unchanged (arrowing back to a family you're already previewing, or
#     re-committing the current theme, touches the file zero times).
#   - Writes to a temp file in the same directory and atomically renames
#     it over settings.json, instead of truncating and rewriting in
#     place. That means Zed (or anything else watching the file) only
#     ever sees a fully-old or fully-new version -- never a half-written
#     one -- even if it happens to read at the exact wrong instant. This
#     is what makes it safe to include in live preview, where the write
#     can happen many times in quick succession while you browse.
#
# Usage: apply-zed-theme.py <settings.json path> <light theme name> <dark theme name>
#
import os
import re
import sys
import tempfile

def main():
    if len(sys.argv) != 4:
        print("Usage: apply-zed-theme.py <settings.json> <light> <dark>", file=sys.stderr)
        return 1

    path, light, dark = sys.argv[1], sys.argv[2], sys.argv[3]

    try:
        with open(path) as f:
            content = f.read()
    except OSError as e:
        print(f"warning: couldn't read {path}: {e}", file=sys.stderr)
        return 0  # not fatal -- caller treats Zed as best-effort

    pattern = re.compile(r'"theme":\s*\{[^}]*\}', re.DOTALL)
    replacement = (
        '"theme": {\n'
        '    "mode": "system",\n'
        f'    "light": "{light}",\n'
        f'    "dark": "{dark}",\n'
        '  }'
    )
    new_content, n = pattern.subn(replacement, content, count=1)

    if n != 1:
        print("warning: no theme block found in settings.json, skipped", file=sys.stderr)
        return 0

    if new_content == content:
        return 0  # already on this theme -- nothing to write

    dir_name = os.path.dirname(path) or "."
    fd, tmp_path = tempfile.mkstemp(dir=dir_name, prefix=".settings-", suffix=".json.tmp")
    try:
        with os.fdopen(fd, "w") as f:
            f.write(new_content)
        os.replace(tmp_path, path)  # atomic on the same filesystem
    except OSError as e:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        print(f"warning: couldn't write {path}: {e}", file=sys.stderr)
        return 0

    return 0

if __name__ == "__main__":
    sys.exit(main())
