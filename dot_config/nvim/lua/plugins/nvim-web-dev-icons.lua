-- rovides Nerd Font icons (glyphs) for use by neovim plugins
return {
  pack = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("nvim-web-devicons").setup({})
  end,
}
