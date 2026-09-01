import { runAppleScript } from "@raycast/utils";

// Ghostty needs to be told to reload its config after switch-theme.sh /
// preview-theme.sh rewrite config.ghostty -- unlike Zed/btop/starship, it
// has no filesystem watcher of its own.
//
// Those shell scripts already try this themselves via a plain `osascript`
// subprocess, but that path turned out to be a dead end: macOS's
// Automation permission system never attributed a request from
// execFile(bash) -> osascript back to Raycast at all -- no prompt ever
// appeared, and no entry showed up in System Settings > Privacy &
// Security > Automation for Cam to grant, even after actually triggering
// a real Switch Theme through Raycast. Running it here instead, through
// Raycast's own AppleScript runner, goes through Raycast's own signed
// process -- which is what actually lets macOS ask "Raycast wants to
// control Ghostty" the normal way, so Cam can approve it once and have it
// stick.
//
// reload_config alone isn't enough to *see* the change immediately, either:
// Ghostty has a known limitation (see e.g. ghostty-org/ghostty issue #1141)
// where reloading the config doesn't repaint text that's already on
// screen -- only new output picks up the new palette, which is why themes
// only seemed to update "when interacting with the terminal." Chaining a
// clear_screen action right after reload_config forces an immediate
// repaint of the visible viewport (scrollback/history is untouched, same
// as pressing Ctrl+L) so the new theme actually shows without needing to
// type anything.
export async function reloadGhosttyConfig() {
  try {
    await runAppleScript(`
      tell application "Ghostty"
        set t to focused terminal of selected tab of front window
        perform action "reload_config" on t
        perform action "clear_screen" on t
      end tell
    `);
  } catch {
    // Best-effort: Ghostty might not be running, might have no open
    // window, or the Automation permission might still be un-granted (in
    // which case macOS should now be prompting for it). Either way the
    // config file itself is already correct -- a manual reload or the
    // next app restart still picks it up.
  }
}
