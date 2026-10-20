-- Bufferline.nvim doesn't create anything new — it just draws a clickable tab bar showing the files (buffers) you already have open in Neovim.
return {
  pack = {
    { src = "akinsho/bufferline.nvim", version = vim.version.range("*") },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("bufferline").setup()
  end,
}
