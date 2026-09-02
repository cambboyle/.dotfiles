-- Reads the shared theme-switcher state (current family + macOS light/dark
-- appearance) and picks the best available Neovim colorscheme for it.
--
-- Most families now get their own dedicated, purpose-built colorscheme
-- plugin (gruvbox.nvim, kanagawa.nvim, catppuccin/nvim, etc.) instead of
-- the generic palette-driven aether.nvim -- these are the exact same
-- plugin choices Omarchy itself ships per-theme (its own bespoke
-- themes/<name>/neovim.lua files, not guessed), plus three more picked to
-- match the 3 families that predate the Omarchy integration (Zedokai/
-- Monokai, Ayu, Kanso) using real, well-known plugins for each.
--
-- A handful of families (the newest, more obscure Omarchy wallpaper packs
-- that don't ship their own neovim.lua either, in Omarchy itself) have no
-- solid dedicated plugin to reach for, so those still fall back to
-- aether.nvim -- a colorscheme plugin built to take an arbitrary custom
-- palette table, fed from families.json's palette_dark/palette_light
-- (itself sourced from Cam's real, currently-installed Ghostty/Omarchy
-- theme data, not hand-typed hex). This is the same "generic fallback"
-- approach Omarchy itself uses for its own theme-less-plugin themes.
--
-- This file is intentionally static -- nothing ever rewrites it. It
-- re-reads the shared state fresh on every Neovim startup, so switching
-- themes elsewhere just means the *next* `nvim` picks up the new look.
-- (Neovim has no generic mechanism to hot-reload a colorscheme's source
-- config the way Ghostty/Zed do, so this -- like Omarchy's own neovim.lua
-- -- is a restart-to-apply feature, not part of the live preview.)

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function trim(s)
  if not s then
    return s
  end
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function current_family()
  local family = trim(read_file(vim.fn.expand("~/.local/state/theme/current-family")))
  if family and family ~= "" then
    return family
  end
  return "gruvbox"
end

local function current_mode()
  -- Mirrors the same check the theme switcher's shell scripts use.
  local status = os.execute("defaults read -g AppleInterfaceStyle >/dev/null 2>&1")
  if status == true or status == 0 then
    return "dark"
  end
  return "light"
end

-- Dedicated colorscheme per family, keyed by current_family()'s value and
-- given the resolved light/dark mode. Returns nil to fall through to the
-- generic aether.nvim palette-driven colorscheme below (used both for
-- families with no solid dedicated plugin, and for zedokai's light mode,
-- where Monokai Pro has no real light variant to reach for).
local DEDICATED = {
  gruvbox = function(mode)
    return {
      spec = { "ellisonleao/gruvbox.nvim", opts = { contrast = "hard" } },
      colorscheme = "gruvbox",
      background = mode,
    }
  end,
  nord = function(_)
    -- EdenEast/nightfox.nvim's "nordfox" variant -- the exact plugin
    -- Omarchy itself ships for Nord. Nightfox has no dedicated Nord-branded
    -- light counterpart, so this is used for both modes.
    return {
      spec = { "EdenEast/nightfox.nvim" },
      colorscheme = "nordfox",
      background = "dark",
    }
  end,
  tokyonight = function(mode)
    return {
      spec = { "folke/tokyonight.nvim", priority = 1000 },
      colorscheme = mode == "dark" and "tokyonight-night" or "tokyonight-day",
      background = mode,
    }
  end,
  catppuccin = function(mode)
    return {
      spec = {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        opts = { flavour = mode == "dark" and "macchiato" or "latte" },
      },
      colorscheme = "catppuccin",
      background = mode,
    }
  end,
  kanagawa = function(mode)
    return {
      spec = { "rebelot/kanagawa.nvim" },
      colorscheme = mode == "dark" and "kanagawa-wave" or "kanagawa-lotus",
      background = mode,
    }
  end,
  everforest = function(mode)
    return {
      spec = {
        "neanias/everforest-nvim",
        opts = { background = mode == "dark" and "hard" or "medium" },
      },
      colorscheme = "everforest",
      background = mode,
    }
  end,
  rosepine = function(mode)
    return {
      spec = { "rose-pine/neovim", name = "rose-pine" },
      colorscheme = mode == "dark" and "rose-pine" or "rose-pine-dawn",
      background = mode,
    }
  end,
  zedokai = function(mode)
    if mode ~= "dark" then
      return nil -- no good Monokai light variant -- falls through to aether.nvim
    end
    return {
      spec = { "loctvl842/monokai-pro.nvim", opts = { filter = "pro" } },
      colorscheme = "monokai-pro",
      background = "dark",
    }
  end,
  ayu = function(mode)
    -- Cam's own prior choice before the Omarchy integration -- brought
    -- back for this family specifically now that dedicated plugins are
    -- being used again.
    return {
      spec = { "Shatur/neovim-ayu" },
      colorscheme = mode == "dark" and "ayu-dark" or "ayu-light",
      background = mode,
    }
  end,
  kanso = function(mode)
    return {
      spec = { "webhooked/kanso.nvim", lazy = false, priority = 1000 },
      colorscheme = mode == "dark" and "kanso-ink" or "kanso-pearl",
      background = mode,
    }
  end,
  hackerman = function(_)
    return {
      spec = {
        "bjarneo/hackerman.nvim",
        dependencies = { "bjarneo/aether.nvim" },
        priority = 1000,
      },
      colorscheme = "hackerman",
      background = "dark",
    }
  end,
  lumon = function(_)
    return {
      spec = { "omacom-io/lumon.nvim", priority = 1000 },
      colorscheme = "lumon",
      background = "dark",
    }
  end,
  osakajade = function(_)
    return {
      spec = { "ribru17/bamboo.nvim", priority = 1000 },
      colorscheme = "bamboo",
      background = "dark",
    }
  end,
  solitude = function(_)
    return {
      spec = { "ficcdaf/ashen.nvim" },
      colorscheme = "ashen",
      background = "dark",
    }
  end,
  retro82 = function(_)
    return {
      spec = { "OldJobobo/retro-82.nvim", priority = 1000 },
      colorscheme = "retro-82",
      background = "dark",
    }
  end,
  matteblack = function(_)
    return {
      spec = { "tahayvr/matteblack.nvim", lazy = false, priority = 1000 },
      colorscheme = "matteblack",
      background = "dark",
    }
  end,
  flexoki = function(_)
    return {
      spec = { "kepano/flexoki-neovim", priority = 1000 },
      colorscheme = "flexoki-light",
      background = "light",
    }
  end,
  -- miasma, lupine, lasthorizon, ristretto, vantablack, ethereal: no solid
  -- dedicated plugin (Omarchy itself has no bespoke neovim.lua for these
  -- either) -- intentionally absent here, falls through to aether.nvim.
}

local family = current_family()
local mode = current_mode()

-- Split light/dark families (e.g. "gruvbox-dark", from separating the
-- original 10 paired families into independent fixed-mode entries) map to
-- the same dedicated colorscheme as their base name ("gruvbox") --
-- DEDICATED below is keyed by base family, not the split entry name, so
-- strip a trailing "-dark"/"-light" before looking it up there. The
-- families.json palette lookup further down uses the raw, unstripped
-- `family` value instead, since families.json itself has a real entry
-- under the split name directly.
local dedicated_family = family:gsub("%-dark$", ""):gsub("%-light$", "")

local dedicated_fn = DEDICATED[dedicated_family]
local dedicated = dedicated_fn and dedicated_fn(mode) or nil

if dedicated then
  vim.o.background = dedicated.background
  return {
    dedicated.spec,
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = dedicated.colorscheme,
      },
    },
  }
end

local function load_palette()
  local families_json = read_file(vim.fn.expand("~/.config/theme/families.json"))
  if not families_json then
    return nil
  end

  local ok, families = pcall(vim.fn.json_decode, families_json)
  if not ok or not families then
    return nil
  end

  local entry = families[family]
  if not entry then
    return nil
  end

  return entry["palette_" .. mode]
end

local palette = load_palette()

-- Fallback: if families.json or the palette fields aren't there for some
-- reason (e.g. this file landed before the theme switcher's palette
-- update), fall back to a plain built-in colorscheme so Neovim never
-- starts up broken.
if not palette then
  return {
    { "LazyVim/LazyVim", opts = { colorscheme = "habamax" } },
  }
end

vim.o.background = mode

return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    lazy = false,
    priority = 1000,
    opts = {
      colors = {
        bg = palette.background,
        dark_bg = palette.dark_background,
        darker_bg = palette.darker_background,
        lighter_bg = palette.lighter_background,

        fg = palette.foreground,
        dark_fg = palette.dark_foreground,
        light_fg = palette.light_foreground,
        bright_fg = palette.bright_foreground,
        muted = palette.muted,

        red = palette.red,
        yellow = palette.yellow,
        orange = palette.orange,
        green = palette.green,
        cyan = palette.cyan,
        blue = palette.blue,
        magenta = palette.magenta,
        brown = palette.brown,

        bright_red = palette.bright_red,
        bright_yellow = palette.bright_yellow,
        bright_green = palette.bright_green,
        bright_cyan = palette.bright_cyan,
        bright_blue = palette.bright_blue,
        bright_magenta = palette.bright_magenta,

        accent = palette.accent,
        cursor = palette.bright_foreground,
        foreground = palette.foreground,
        background = palette.background,
        selection = palette.selection,
        selection_foreground = palette.selection_foreground,
        selection_background = palette.selection_background,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
