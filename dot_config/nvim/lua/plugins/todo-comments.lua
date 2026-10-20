-- Highlights and lists TODO, FIXME, NOTE, and similar comment tags
return {
  pack = {
    "folke/todo-comments.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("todo-comments").setup({
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    })
  end,
}
