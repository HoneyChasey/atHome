-- Plugin for status line written in pure lua. Change the config inside the folder config
return {
  pack = {
    "nvim-lualine/lualine.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("configs.lualine")
  end,
}
