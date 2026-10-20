-- Plugin for adding color to code

-- Repetition of code i know but cleanner to have file here (already implemented by Nvchad team)
return {
  pack = {
    { src = "nvim-treesitter/nvim-treesitter", data = { build = ":TSUpdate" } },
  },
  ensure_installed = { "svelte" }, -- parsers installed by :TSInstallAll
}
