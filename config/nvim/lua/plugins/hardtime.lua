-- Nudges you away from inefficient habits (holding arrow keys, mashing hjkl)
-- toward proper vim motions, in the moment, as you actually type -- instead
-- of a tutorial you'd have to sit down and do separately.
--
-- Set to "hint" mode rather than the plugin's default "block" mode: it'll
-- suggest a better key instead of refusing to let you press the one you
-- used. Once the suggestions stop feeling surprising (a couple weeks in),
-- flip restriction_mode below to "block" for the stricter version.
return {
  "m4xshen/hardtime.nvim",
  lazy = false,
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    restriction_mode = "hint",
  },
}
