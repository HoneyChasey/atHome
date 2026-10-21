-- Toggle a floating or split terminal inside neovim
return {
  pack = {
    { src = "akinsho/toggleterm.nvim", version = vim.version.range("*") },
  },
  config = function()
    require("toggleterm").setup({})
  end,
}
