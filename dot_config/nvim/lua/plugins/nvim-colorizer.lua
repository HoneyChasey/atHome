-- Highlights color codes (#hex, rgb, etc.) with their actual color
return {
  pack = { "norcalli/nvim-colorizer.lua" },
  config = function()
    require("colorizer").setup()
  end,
}
