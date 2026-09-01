import { ActionPanel, Action, List, closeMainWindow, showHUD, showToast, Toast, useNavigation } from "@raycast/api";
import { useEffect, useState } from "react";
import { readFileSync } from "fs";
import { execFile } from "child_process";
import { homedir } from "os";
import path from "path";
import { DiscoverWallpapers } from "./discover-wallpapers";
import { AddOwnWallpaper } from "./add-own-wallpaper";
import { reloadGhosttyConfig } from "./lib/reload-ghostty";

const FAMILIES_PATH = path.join(homedir(), ".config", "theme", "families.json");
const SET_WALLPAPER_SCRIPT = path.join(homedir(), ".config", "theme", "set-wallpaper.sh");
const SWITCH_SCRIPT = path.join(homedir(), ".config", "theme", "switch-theme.sh");

interface FamilyEntry {
  display_name: string;
  wallpapers_dark: string[];
  wallpapers_light: string[];
  search_query?: string;
}

function loadFamily(familyKey: string): FamilyEntry | undefined {
  try {
    const raw = readFileSync(FAMILIES_PATH, "utf-8");
    const parsed = JSON.parse(raw);
    return parsed[familyKey];
  } catch {
    return undefined;
  }
}

// Pushed from Switch Theme's "Change Wallpaper..." action -- scoped to
// whichever family + mode was active there, rather than living as its own
// top-level command. `onCommit` lets the parent list know a real switch
// happened here, so its own "revert if you back out without picking
// anything" cleanup doesn't undo it (see switch-theme.tsx).
export function WallpaperPicker({
  familyKey,
  mode,
  onCommit,
}: {
  familyKey: string;
  mode: "dark" | "light";
  onCommit?: () => void;
}) {
  const { push } = useNavigation();
  const [entry, setEntry] = useState<FamilyEntry | undefined>(() => loadFamily(familyKey));

  useEffect(() => {
    setEntry(loadFamily(familyKey));
  }, [familyKey]);

  // Passed down to Discover and Add Your Own so a newly-added wallpaper
  // shows up here as soon as you pop back, without having to leave and
  // re-enter this view.
  function refresh() {
    setEntry(loadFamily(familyKey));
  }

  const wallpapers = entry ? (mode === "dark" ? entry.wallpapers_dark : entry.wallpapers_light) : [];
  const displayName = entry?.display_name ?? familyKey;

  return (
    <List isShowingDetail searchBarPlaceholder="Search wallpapers...">
      {wallpapers.map((filename, i) => (
        <List.Item
          key={filename}
          title={i === 0 ? `${filename} (default)` : filename}
          detail={<List.Item.Detail markdown={`![preview](wallpapers/${filename}?raycast-width=380)`} />}
          actions={
            <ActionPanel>
              <Action
                title="Set Wallpaper & Switch Theme"
                onAction={async () => {
                  // Picking a wallpaper here now commits the *whole* theme
                  // (Ghostty + Zed + borders), same as pressing Enter on
                  // Switch Theme -- just with this exact wallpaper instead
                  // of the family's default. Sequenced as two scripts:
                  // set-wallpaper.sh writes the persisted choice first, so
                  // switch-theme.sh (which resolves the wallpaper via that
                  // same persisted-choice file) picks up this filename
                  // rather than the array default.
                  const toast = await showToast({ style: Toast.Style.Animated, title: "Switching..." });
                  const quietEnv = { ...process.env, THEME_SWITCH_QUIET: "1" };
                  execFile(SET_WALLPAPER_SCRIPT, [familyKey, mode, filename], { env: quietEnv }, (err1) => {
                    if (err1) {
                      toast.style = Toast.Style.Failure;
                      toast.title = "Couldn't set wallpaper";
                      toast.message = err1.message;
                      return;
                    }
                    execFile(SWITCH_SCRIPT, [familyKey], { env: quietEnv }, async (err2) => {
                      if (err2) {
                        toast.style = Toast.Style.Failure;
                        toast.title = "Wallpaper set, but theme switch failed";
                        toast.message = err2.message;
                        return;
                      }
                      // Nudge Ghostty to pick up the rewritten config live
                      // -- see lib/reload-ghostty.ts for why this goes
                      // through Raycast's own AppleScript runner instead of
                      // switch-theme.sh's own (silently permission-blocked)
                      // osascript call.
                      void reloadGhosttyConfig();
                      // Tell the parent Switch Theme list this counts as a
                      // real commit *before* closing the window -- closing
                      // unmounts the whole navigation stack, and without
                      // this its cleanup effect would think you backed out
                      // and revert straight back to the original theme.
                      onCommit?.();
                      await closeMainWindow();
                      await showHUD(`Theme: ${displayName} (${mode === "dark" ? "Dark" : "Light"})`);
                    });
                  });
                }}
              />
              <Action
                title="Discover More Wallpapers..."
                // Same reasoning as Change Wallpaper's shortcut in
                // switch-theme.tsx -- Cmd+Shift+D avoids anything Raycast
                // reserves, and this row is always clickable via Cmd+K too.
                shortcut={{ modifiers: ["cmd", "shift"], key: "d" }}
                onAction={() =>
                  push(
                    <DiscoverWallpapers
                      familyKey={familyKey}
                      mode={mode}
                      displayName={displayName}
                      defaultQuery={entry?.search_query ?? displayName}
                      onAdded={refresh}
                    />,
                  )
                }
              />
              <Action
                title="Add Your Own Wallpaper..."
                shortcut={{ modifiers: ["cmd", "shift"], key: "a" }}
                onAction={() =>
                  push(
                    <AddOwnWallpaper familyKey={familyKey} mode={mode} displayName={displayName} onAdded={refresh} />,
                  )
                }
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
