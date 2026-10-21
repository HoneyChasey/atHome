-- Incremental rename with live preview as you type
return {
  pack = { "smjonas/inc-rename.nvim" },
  config = function()
    require("inc_rename").setup({})
  end,
}
