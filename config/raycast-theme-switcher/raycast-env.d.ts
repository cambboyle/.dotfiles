/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `switch-theme` command */
  export type SwitchTheme = ExtensionPreferences & {}
  /** Preferences accessible in the `sync-wallpaper` command */
  export type SyncWallpaper = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `switch-theme` command */
  export type SwitchTheme = {}
  /** Arguments passed to the `sync-wallpaper` command */
  export type SyncWallpaper = {}
}

