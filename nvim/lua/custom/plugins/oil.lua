-- Oil.nvim - Edit your filesystem like a buffer
return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    keymaps = {
      -- Disable C-h since it conflicts with window navigation
      ['<C-h>'] = false,
      -- Disable C-l since it conflicts with window navigation
      ['<C-l>'] = false,
    },
  },
  -- Optional dependencies
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    { '-', '<cmd>Oil<cr>', desc = 'Open parent directory (floating)' },
  },
}
