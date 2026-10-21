-- Auto closes brackets, quotes, and pairs while typing
return {
  pack = { "windwp/nvim-autopairs" },
  config = function()
    require("nvim-autopairs").setup({})
  end,
}
