return {
  {
    "0x96f-org/0x96f.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "Shatur/neovim-ayu",
    lazy = false,
    priority = 1000,
    config = function()
      require("ayu").setup({
        mirage = false,
      })
    end,
  },
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 999,
    opts = {
      update_interval = 3000,
      set_dark_mode = function()
        vim.cmd("colorscheme 0x96f")
      end,
      set_light_mode = function()
        vim.cmd("colorscheme ayu-light")
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "0x96f",
    },
  },
}
