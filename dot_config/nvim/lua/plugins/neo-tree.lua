-- display a tree of your current files. I add this if i really need to have tree file structure inside neovim. This is why i use leader + tr (for leader tree)
return {
  pack = {
    { src = "nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons", -- optional, but recommended
  },
  config = function()
    require("configs.neo-tree")
  end,
}
