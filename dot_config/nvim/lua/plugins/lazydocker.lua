-- Integration of lazydocker inside neovim
return {
  pack = { "HoneyChasey/lazydocker.nvim" },
  config = function()
    require("lazydocker").setup({})

    vim.keymap.set("n", "<leader>ld", function()
      require("lazydocker").open()
    end, { desc = "Open Lazydocker" })
  end,
}
