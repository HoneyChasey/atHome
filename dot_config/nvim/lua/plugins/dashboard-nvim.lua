-- dashboad when opening your neovim
return {
  pack = {
    "nvimdev/dashboard-nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("configs.dashboard-nvim")
  end,
}
