import { ActionPanel, Action, List, closeMainWindow, showHUD, useNavigation } from "@raycast/api";
import { useEffect, useRef, useState } from "react";
import { readFileSync } from "fs";
import { execFile, execFileSync } from "child_process";
import { homedir } from "os";
import path from "path";
import { WallpaperPicker } from "./wallpaper-picker";
import { reloadGhosttyConfig } from "./lib/reload-ghostty";

const FAMILIES_PATH = path.join(homedir(), ".config", "theme", "families.json");
const SWITCH_SCRIPT = path.join(homedir(), ".config", "theme", "switch-theme.sh");
const PREVIEW_SCRIPT = path.join(homedir(), ".config", "theme", "preview-theme.sh");
const CURRENT_FAMILY_PATH = path.join(homedir(), ".local", "state", "theme", "current-family");

// How long to wait after the selection stops moving before applying a
// preview. Keeps holding down an arrow key from queueing up a pile of
// Ghostty/Zed/borders writes -- only the family you land on gets applied.
const PREVIEW_DEBOUNCE_MS = 250;

interface FamilyEntry {
  ghostty_dark: string;
  ghostty_light: string;
  wallpapers_dark: string[];
  wallpapers_light: string[];
  display_name: string;
}

function getCurrentMode(): "dark" | "light" {
  try {
    execFileSync("defaults", ["read", "-g", "AppleInterfaceStyle"]);
    return "dark";
  } catch {
    return "light";
  }
}

function getCurrentFamily(): string {
  try {
    return readFileSync(CURRENT_FAMILY_PATH, "utf-8").trim();
  } catch {
    return "";
  }
}

function runPreview(family: string) {
  // Once the script has rewritten config.ghostty, nudge Ghostty to pick it
  // up live -- see lib/reload-ghostty.ts for why this goes through
  // Raycast's own AppleScript runner instead of the script's own (silently
  // permission-blocked) osascript call.
  execFile(PREVIEW_SCRIPT, [family], () => {
    void reloadGhosttyConfig();
  });
}

export default function Command() {
  const { push } = useNavigation();
  const [families, setFamilies] = useState<Record<string, FamilyEntry>>({});
  const [mode] = useState<"dark" | "light">(getCurrentMode());

  // Tracks whether the user actually committed a theme (pressed Enter). If
  // they back out without doing that, the cleanup effect below restores
  // whatever was active when the picker opened.
  const committedRef = useRef(false);
  const originalFamilyRef = useRef<string>("");
  const lastPreviewedRef = useRef<string>("");
  const selectionEventCountRef = useRef(0);
  const debounceTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    try {
      const raw = readFileSync(FAMILIES_PATH, "utf-8");
      setFamilies(JSON.parse(raw));
    } catch {
      setFamilies({});
    }
    const current = getCurrentFamily();
    originalFamilyRef.current = current;
    lastPreviewedRef.current = current;

    return () => {
      if (debounceTimer.current) clearTimeout(debounceTimer.current);
      // Backed out without picking anything -- put the original theme's
      // full look back (wallpaper/Ghostty/Zed/borders), since preview
      // applies all four now.
      if (!committedRef.current && originalFamilyRef.current) {
        runPreview(originalFamilyRef.current);
      }
    };
  }, []);

  function handleSelectionChange(id: string | null) {
    selectionEventCountRef.current += 1;
    // The first callback just reports Raycast's initial highlight (usually
    // not even the currently-active theme) -- skip it so opening the
    // picker doesn't itself change anything before you've touched a key.
    if (selectionEventCountRef.current <= 1) return;
    if (!id || id === lastPreviewedRef.current) return;

    if (debounceTimer.current) clearTimeout(debounceTimer.current);
    debounceTimer.current = setTimeout(() => {
      lastPreviewedRef.current = id;
      runPreview(id);
    }, PREVIEW_DEBOUNCE_MS);
  }

  return (
    <List isShowingDetail searchBarPlaceholder="Search themes..." onSelectionChange={handleSelectionChange}>
      {Object.entries(families).map(([key, entry]) => {
        const wallpapers = mode === "dark" ? entry.wallpapers_dark : entry.wallpapers_light;
        const wallpaper = wallpapers?.[0];
        const ghosttyName = mode === "dark" ? entry.ghostty_dark : entry.ghostty_light;
        return (
          <List.Item
            key={key}
            id={key}
            title={entry.display_name}
            subtitle={ghosttyName}
            detail={<List.Item.Detail markdown={`![preview](wallpapers/${wallpaper}?raycast-width=380)`} />}
            actions={
              <ActionPanel>
                <Action
                  title={`Switch to ${entry.display_name}`}
                  onAction={async () => {
                    if (debounceTimer.current) clearTimeout(debounceTimer.current);
                    committedRef.current = true;
                    await closeMainWindow();
                    execFile(
                      SWITCH_SCRIPT,
                      [key],
                      { env: { ...process.env, THEME_SWITCH_QUIET: "1" } },
                      () => {
                        void reloadGhosttyConfig();
                      },
                    );
                    await showHUD(`Theme: ${entry.display_name} (${mode === "dark" ? "Dark" : "Light"})`);
                  }}
                />
                <Action
                  title="Change Wallpaper..."
                  // Plain Cmd+W is reserved by Raycast itself to close the
                  // window, so it never reaches this action -- Cmd+Shift+W
                  // is free. Either way this row is always just a click
                  // away in the action panel (Cmd+K), no shortcut needed.
                  shortcut={{ modifiers: ["cmd", "shift"], key: "w" }}
                  onAction={() =>
                    push(
                      <WallpaperPicker
                        familyKey={key}
                        mode={mode}
                        onCommit={() => {
                          // Picking a wallpaper in there now fully switches
                          // the theme too, so treat it exactly like this
                          // list's own "Switch to X" -- don't revert on
                          // the way out.
                          if (debounceTimer.current) clearTimeout(debounceTimer.current);
                          committedRef.current = true;
                        }}
                      />,
                    )
                  }
                />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}
