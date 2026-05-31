-- Yazi file manager integration
return {
  'mikavilpas/yazi.nvim',
  version = '*',
  event = 'VeryLazy',
  dependencies = {
    { 'nvim-lua/plenary.nvim', lazy = true },
  },
  keys = {
    {
      '<leader>-',
      '<cmd>Yazi<cr>',
      mode = { 'n', 'v' },
      desc = 'Open yazi at current file',
    },
    {
      '<leader>cw',
      '<cmd>Yazi cwd<cr>',
      desc = "Open file manager in nvim's working directory",
    },
    {
      '<c-up>',
      '<cmd>Yazi toggle<cr>',
      desc = 'Resume last yazi session',
    },
  },
  opts = {
    open_for_directories = false,
    keymaps = {
      show_help = '<f1>',
    },
  },
}
