-- VimTeX configuration goes here, e.g.
-- (set before the plugin is loaded, like lazy's `init`)
vim.g.vimtex_view_method = "zathura"

return {
  pack = {
    "lervag/vimtex",
    -- { src = "lervag/vimtex", version = "v2.15" }, -- uncomment to pin to a specific release
  },
}
