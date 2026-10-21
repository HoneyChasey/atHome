-- Plugin for auto configuration of lsp config --
return {
  pack = { "neovim/nvim-lspconfig" },
  config = function()
    require("configs.lspconfig")
  end,
}
