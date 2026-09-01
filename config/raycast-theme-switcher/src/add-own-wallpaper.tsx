import { ActionPanel, Action, Form, showToast, Toast, useNavigation } from "@raycast/api";
import { useState } from "react";
import { execFile } from "child_process";
import { homedir } from "os";
import path from "path";

const ADD_WALLPAPER_SCRIPT = path.join(homedir(), ".config", "theme", "add-wallpaper.sh");

interface FormValues {
  file: string[];
  url: string;
}

// Pushed from the wallpaper picker's "Add Your Own Wallpaper..." action.
// Takes either a local image (file picker) or a URL, not both -- either
// way it's handed straight to add-wallpaper.sh, which downloads/copies,
// normalizes with sips, and registers it into that family+mode's array
// exactly like a Discover pick does. `onAdded` refreshes the wallpaper
// picker's list so the new file shows up as soon as you pop back to it.
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

  function handleSubmit(values: FormValues) {
    const filePath = values.file?.[0];
    const url = values.url?.trim();

    setFileError(undefined);
    setUrlError(undefined);

    if (!filePath && !url) {
      setFileError("Pick a file or paste a URL below");
      return;
    }
    if (filePath && url) {
      setUrlError("Use only one of these, not both");
      return;
    }

    const source = filePath || url!;
    setIsLoading(true);

    execFile(ADD_WALLPAPER_SCRIPT, [familyKey, mode, source], async (error, stdout, stderr) => {
      setIsLoading(false);
      if (error) {
        await showToast({
          style: Toast.Style.Failure,
          title: "Couldn't add wallpaper",
          message: stderr?.trim() || error.message,
        });
        return;
      }
      await showToast({
        style: Toast.Style.Success,
        title: `Added to ${displayName}`,
        message: stdout.trim(),
      });
      onAdded();
      pop();
    });
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
      <Form.Description text={`Add a wallpaper to ${displayName}'s ${mode} set -- pick a local image OR paste an image URL, not both.`} />
      <Form.FilePicker
        id="file"
        title="Image File"
        allowMultipleSelection={false}
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
