-- File explorer that opens directories as editable buffers
return {
  pack = {
    "stevearc/oil.nvim",
    -- Optional dependencies
    -- "nvim-mini/mini.icons",
    "nvim-tree/nvim-web-devicons", -- use if you prefer nvim-web-devicons
  },
  config = function()
    require("configs.oil")
  end,
}
