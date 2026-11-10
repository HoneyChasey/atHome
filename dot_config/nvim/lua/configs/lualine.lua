-- Minimal statusline inspired by jakmaz/dotfiles

-- Time when Neovim was opened, used to show the coding session duration
local start_time = os.time()

require('lualine').setup {
  options = {
    theme = 'auto',
    component_separators = '',
    section_separators = '',
    globalstatus = true,
    disabled_filetypes = { statusline = { 'dashboard' } },
  },

  sections = {
    lualine_a = {},
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { { 'filename', path = 1 } },
    lualine_x = {
      -- LSP status (dimmed when no client is attached)
      {
        function() return '󰒋' end,
        color = function()
          if #vim.lsp.get_clients { bufnr = 0 } > 0 then return nil end
          return 'Comment'
        end,
      },
      -- Current Vim mode (NORMAL, INSERT, VISUAL...)
      'mode',
      -- Coding session duration
      {
        function()
          local secs = os.time() - start_time
          return string.format('󱑆 %dh%02dm', math.floor(secs / 3600), math.floor(secs % 3600 / 60))
        end,
      },
    },
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },

  -- Buffer list at the top of the screen (replaces bufferline.nvim)
  tabline = {
    lualine_a = {
      {
        'buffers',
        show_filename_only = true,
        symbols = { modified = ' ●', alternate_file = '', directory = '' },
      },
    },
    lualine_z = { 'tabs' },
  },
}
