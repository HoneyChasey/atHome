vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- install + load all plugins from lua/plugins/ and lua/themes/ with vim.pack

-- bootstrap for theemes

vim.opt.termguicolors = true -- Without this, color highlighting won't render correctly (or at all) in many terminals. Also is use and necessary for the plugin nvim-colorizer.lua

require "options"
require "autocmds"
require("configs.filetype")
require("plugins.init")



vim.cmd.colorscheme("tokyonight") -- change here your default theme

vim.schedule(function()
  require "mappings"
end)
