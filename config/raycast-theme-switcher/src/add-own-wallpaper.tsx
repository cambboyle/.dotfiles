import { ActionPanel, Action, Form, showToast, Toast, useNavigation } from "@raycast/api";
import { useState } from "react";
import { execFile } from "child_process";
import { promisify } from "util";
import { homedir } from "os";
import path from "path";

const execFileAsync = promisify(execFile);
const ADD_WALLPAPER_SCRIPT = path.join(homedir(), ".config", "theme", "add-wallpaper.sh");

interface FormValues {
  file: string[];
  url: string;
}

// Pushed from the wallpaper picker's "Add Your Own Wallpaper..." action.
// Takes either one or more local images (file picker, multi-select) or a
// single URL, not both -- each file is handed to add-wallpaper.sh in turn,
// which downloads/copies, normalizes with sips, and registers it into that
// family+mode's array exactly like a Discover pick does. Files are added
// ONE AT A TIME, awaited in sequence rather than fired in parallel --
// add-wallpaper.sh does a read-modify-write of families.json (and derives
// the next filename from the array's current length), so running several
// at once would race and could clobber each other's edits or collide on
// the same target filename. `onAdded` refreshes the wallpaper picker's
// list so the new files show up as soon as you pop back to it.
export function AddOwnWallpaper({
  familyKey,
  mode,
  displayName,
  onAdded,
}: {
  familyKey: string;
  mode: "dark" | "light";
  displayName: string;
  onAdded: () => void;
}) {
  const { pop } = useNavigation();
  const [isLoading, setIsLoading] = useState(false);
  const [fileError, setFileError] = useState<string | undefined>();
  const [urlError, setUrlError] = useState<string | undefined>();

  async function handleSubmit(values: FormValues) {
    const filePaths = (values.file ?? []).filter(Boolean);
    const url = values.url?.trim();

    setFileError(undefined);
    setUrlError(undefined);

    if (filePaths.length === 0 && !url) {
      setFileError("Pick one or more files or paste a URL below");
      return;
    }
    if (filePaths.length > 0 && url) {
      setUrlError("Use only one of these, not both");
      return;
    }

    setIsLoading(true);

    if (url) {
      try {
        const { stdout } = await execFileAsync(ADD_WALLPAPER_SCRIPT, [familyKey, mode, url]);
        setIsLoading(false);
        await showToast({ style: Toast.Style.Success, title: `Added to ${displayName}`, message: stdout.trim() });
        onAdded();
        pop();
      } catch (err) {
        setIsLoading(false);
        const e = err as { message?: string; stderr?: string };
        await showToast({
          style: Toast.Style.Failure,
          title: "Couldn't add wallpaper",
          message: e.stderr?.trim() || e.message,
        });
      }
      return;
    }

    // Batch path: one file at a time, in order, so each add sees the
    // previous one's update to families.json before deriving its own
    // filename.
    let added = 0;
    let lastError = "";
    for (const [i, filePath] of filePaths.entries()) {
      const toast = await showToast({
        style: Toast.Style.Animated,
        title: `Adding ${i + 1} of ${filePaths.length}...`,
        message: path.basename(filePath),
      });
      try {
        await execFileAsync(ADD_WALLPAPER_SCRIPT, [familyKey, mode, filePath]);
        added += 1;
        await toast.hide();
      } catch (err) {
        const e = err as { message?: string; stderr?: string };
        lastError = e.stderr?.trim() || e.message || "unknown error";
        toast.style = Toast.Style.Failure;
        toast.title = `Failed: ${path.basename(filePath)}`;
        toast.message = lastError;
      }
    }

    setIsLoading(false);

    if (added === filePaths.length) {
      await showToast({
        style: Toast.Style.Success,
        title: `Added ${added} wallpaper${added === 1 ? "" : "s"} to ${displayName}`,
      });
      onAdded();
      pop();
    } else if (added > 0) {
      await showToast({
        style: Toast.Style.Failure,
        title: `Added ${added} of ${filePaths.length} -- ${filePaths.length - added} failed`,
        message: lastError,
      });
      onAdded();
    } else {
      await showToast({ style: Toast.Style.Failure, title: "Couldn't add any wallpapers", message: lastError });
    }
  }

  return (
    <Form
      isLoading={isLoading}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Add to Picker" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.Description
        text={`Add wallpaper(s) to ${displayName}'s ${mode} set -- pick one or more local images OR paste a single image URL, not both.`}
      />
      <Form.FilePicker
        id="file"
        title="Image File(s)"
        allowMultipleSelection={true}
        canChooseDirectories={false}
        error={fileError}
        onChange={() => setFileError(undefined)}
      />
      <Form.TextField
        id="url"
        title="Or Image URL"
        placeholder="https://..."
        error={urlError}
        onChange={() => setUrlError(undefined)}
      />
    </Form>
  );
}
