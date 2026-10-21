-- Fuzzy finder for files, text, buffers, and more
return {
  pack = {
    { src = "nvim-telescope/telescope.nvim", version = vim.version.range("*") },
    "nvim-lua/plenary.nvim",
    -- optional but recommended
    { src = "nvim-telescope/telescope-fzf-native.nvim", data = { build = "make" } },
  },
}
