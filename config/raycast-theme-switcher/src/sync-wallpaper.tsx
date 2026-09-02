import { showHUD, showToast, Toast, Clipboard } from "@raycast/api";
import { execFile } from "child_process";
import { promisify } from "util";
import { writeFileSync } from "fs";
import { homedir } from "os";
import path from "path";

const execFileAsync = promisify(execFile);

// No-view command so it can be bound to its own hotkey (Raycast Preferences
// > Extensions > Theme Switcher) -- run it whenever a Space is showing a
// stale wallpaper and you want the currently-selected theme's wallpaper
// forced onto every Space. Not run automatically on every switch: it
// briefly visits each Space via yabai to apply it (the only way left to
// reach every Space on modern macOS -- see sync-wallpaper-all-spaces.sh),
// which takes a couple of visible seconds.
const SCRIPT = path.join(homedir(), ".config", "theme", "sync-wallpaper-all-spaces.sh");

// A no-view command's toast can vanish the instant the extension process
// gets torn down (which happens right after this function returns) --
// too fast to read, let alone copy, especially for a Failure toast that's
// supposed to persist. Logging the error to a plain file instead means it
// can be read after the fact with no race against the UI at all.
const ERROR_LOG = path.join(homedir(), ".dotfiles", "config", "theme", "sync-wallpaper-error.log");

export default async function Command() {
  const toast = await showToast({ style: Toast.Style.Animated, title: "Syncing wallpaper to all Spaces..." });
  try {
    // Awaited on purpose -- the script takes a couple of seconds (it visits
    // every Space in turn), and a no-view command's extension process can
    // get torn down as soon as this function's returned promise resolves,
    // killing the still-running child if it isn't awaited.
    const { stdout, stderr } = await execFileAsync(SCRIPT, []);
    try {
      writeFileSync(ERROR_LOG, `${new Date().toISOString()} OK\n${[stdout, stderr].filter(Boolean).join("\n")}\n`);
    } catch {
      // best-effort logging only
    }
    await toast.hide();
    await showHUD("Wallpaper synced to all Spaces");
  } catch (err) {
    const e = err as { message?: string; stderr?: string; stdout?: string };
    const detail = [e.stdout, e.stderr, e.message].filter(Boolean).join("\n").trim() || String(err);
    try {
      writeFileSync(ERROR_LOG, `${new Date().toISOString()} FAILED\n${detail}\n`);
    } catch {
      // best-effort logging only
    }
    toast.style = Toast.Style.Failure;
    toast.title = "Couldn't sync wallpaper (see sync-wallpaper-error.log)";
    toast.message = detail;
    toast.primaryAction = {
      title: "Copy Error",
      onAction: async () => {
        await Clipboard.copy(detail);
      },
    };
  }
}
