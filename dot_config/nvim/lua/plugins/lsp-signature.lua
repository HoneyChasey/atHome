-- Shows function signature hints while typing arguments
return {
  pack = { "ray-x/lsp_signature.nvim" },
  config = function()
    require("lsp_signature").setup({
      -- cfg options
    })
  end,
}
