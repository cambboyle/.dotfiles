-- Pin the handful of files you're bouncing between on a ticket (entity,
-- service, controller, test) and jump straight to any of them with one
-- keypress instead of re-searching each time.
--
-- <leader>H       pin (add) current file
-- <leader>1-9     jump to pinned file 1-9
-- <leader>h       open the quick menu (see/reorder/remove pins)
return {
  { import = "lazyvim.plugins.extras.editor.harpoon2" },
}
