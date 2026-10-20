-- Formator plugin (indentation, spacing, line, lenght etc etc).
return {
  pack = { "stevearc/conform.nvim" },
  config = function()
    require("conform").setup(require("configs.conform"))
  end,
}
