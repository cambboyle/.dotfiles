-- Auto-restore the last session (open files + layout) when nvim starts,
-- scoped to the current directory and git branch -- persistence.nvim
-- (already bundled with LazyVim) saves a separate session per
-- directory+branch automatically, it just doesn't auto-load by default.
--
-- Since each of your tmux windows `cd`s into a different project before
-- running `nvim .`, this means: reopen the notes window, get your notes
-- session back; reopen a dev window, get that project's session back --
-- without any extra step.
--
-- Only triggers when nvim starts with no args or just a directory (e.g.
-- `nvim .`, matching your tmux setup) -- opening a specific file directly
-- (`nvim somefile.ts`) skips auto-restore so it doesn't get in the way.
return {
  "folke/persistence.nvim",
  optional = true,
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("auto_restore_session", { clear = true }),
      nested = true,
      callback = function()
        if vim.fn.argc() > 0 then
          local first_arg = vim.fn.argv(0)
          if vim.fn.isdirectory(first_arg) == 0 then
            return
          end
        end
        require("persistence").load()
      end,
    })
  end,
}
