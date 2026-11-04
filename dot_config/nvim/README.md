# nvim-config

## Updating plugins

Plugins are managed with `vim.pack`. To update them all:

1. Run `:PackUpdate` (defined in `lua/plugins/init.lua`; it calls `vim.pack.update()`).
2. A buffer opens showing the pending changes. Type `:write` to apply them, or `:quit` to cancel.

You can also call it directly with `:lua vim.pack.update()`.
