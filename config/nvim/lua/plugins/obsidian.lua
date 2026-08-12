return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  ft = "markdown",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
    { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Open/find note" },
    { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Browse by tag" },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
    { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search all notes" },
  },
  opts = function()
    return {
      legacy_commands = false,
      workspaces = {
        { name = "cameron", path = "~/cameron" },
      },
      notes_subdir = "notes",
      new_notes_location = "notes_subdir",
      note_id_func = require("obsidian.builtin").title_id, -- readable-slug filenames, matches your existing style
      daily_notes = { enabled = false },
      templates = { folder = "templates" },
      note = { template = "note.md" },
      frontmatter = { enabled = false }, -- your template already writes tags, don't double up
      picker = { name = "telescope.nvim" },
    }
  end,
}
