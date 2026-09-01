import { ActionPanel, Action, List, showToast, Toast } from "@raycast/api";
import { useEffect, useRef, useState } from "react";
import { execFile } from "child_process";
import { homedir } from "os";
import path from "path";

const ADD_WALLPAPER_SCRIPT = path.join(homedir(), ".config", "theme", "add-wallpaper.sh");
const SEARCH_DEBOUNCE_MS = 400;

interface WallhavenResult {
  id: string;
  path: string;
  resolution: string;
  file_size: number;
  thumbs: { large: string };
}

// Pushed from the wallpaper picker's "Discover More Wallpapers..." action.
// Searches Wallhaven (no API key needed for general SFW search) seeded
// with the family's default query, but the search bar can override it --
// good for narrowing ("mountains", "minimal") or just browsing more of the
// same vibe. "Add to Picker" downloads, normalizes, and files the pick
// into that family+mode's wallpaper set via add-wallpaper.sh.
export function DiscoverWallpapers({
  familyKey,
  mode,
  displayName,
  defaultQuery,
  onAdded,
}: {
  familyKey: string;
  mode: "dark" | "light";
  displayName: string;
  defaultQuery: string;
  onAdded?: () => void;
}) {
  const [searchText, setSearchText] = useState("");
  const [results, setResults] = useState<WallhavenResult[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [addedIds, setAddedIds] = useState<Set<string>>(new Set());
  const debounceTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (debounceTimer.current) clearTimeout(debounceTimer.current);
    debounceTimer.current = setTimeout(() => {
      runSearch(searchText.trim() || defaultQuery);
    }, SEARCH_DEBOUNCE_MS);
    return () => {
      if (debounceTimer.current) clearTimeout(debounceTimer.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchText]);

  async function runSearch(query: string) {
    setIsLoading(true);
    try {
      const url = `https://wallhaven.cc/api/v1/search?q=${encodeURIComponent(query)}&categories=100&purity=100&sorting=relevance&per_page=24`;
      const res = await fetch(url);
      if (!res.ok) throw new Error(`Wallhaven returned ${res.status}`);
      const json = (await res.json()) as { data: WallhavenResult[] };
      setResults(json.data ?? []);
    } catch (err) {
      setResults([]);
      await showToast({
        style: Toast.Style.Failure,
        title: "Couldn't reach Wallhaven",
        message: err instanceof Error ? err.message : String(err),
      });
    } finally {
      setIsLoading(false);
    }
  }

  async function addToPicker(result: WallhavenResult) {
    const toast = await showToast({ style: Toast.Style.Animated, title: "Downloading..." });
    execFile(ADD_WALLPAPER_SCRIPT, [familyKey, mode, result.path], async (error, stdout, stderr) => {
      if (error) {
        toast.style = Toast.Style.Failure;
        toast.title = "Couldn't add wallpaper";
        toast.message = stderr?.trim() || error.message;
        return;
      }
      setAddedIds((prev) => new Set(prev).add(result.id));
      onAdded?.();
      toast.style = Toast.Style.Success;
      toast.title = `Added to ${displayName}`;
      toast.message = stdout.trim();
    });
  }

  return (
    <List
      isShowingDetail
      isLoading={isLoading}
      searchBarPlaceholder={`Search Wallhaven (default: "${defaultQuery}")`}
      onSearchTextChange={setSearchText}
      throttle
    >
      {results.map((result) => (
        <List.Item
          key={result.id}
          title={result.resolution}
          accessories={addedIds.has(result.id) ? [{ text: "Added" }] : []}
          detail={<List.Item.Detail markdown={`![preview](${result.thumbs.large})`} />}
          actions={
            <ActionPanel>
              <Action title={`Add to ${displayName}`} onAction={() => addToPicker(result)} />
              <Action.OpenInBrowser title="Open on Wallhaven" url={result.path} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
