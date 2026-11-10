-- This files only contain the array of servers used by mason-lspconfig, mason, and nvim-lspconfig


return { "html", "cssls", "bashls", "clangd", "dockerls", "docker_compose_language_service", "gopls", "jdtls", "lua_ls", "pyright", "svelte", "rust_analyzer", "texlab", "nil_ls", "terraformls"}
-- Write here all the the name of lsp you want to enable. To get their name, please refer to https://github.com/neovim/nvim-lspconfig--


--Exemple i want to add enable svelte to my nvim go to the repo and search the name of the language.--
-- We have nvim-lspconfig/lua/lspconfig/configs/svelte.lua
                                              --^^^^^^
                                              -- And look the cmd called in the configuration file. Like what file is called in the fucntion
                                              --
-- When you add a name to your servers list, Neovim looks for a file with that name in lspconfig's configs folder, reads it to know which binary to run and how to start it to import the lspconfiguration to the neovim config
