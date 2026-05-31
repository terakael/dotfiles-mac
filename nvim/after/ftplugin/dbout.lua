-- Filetype plugin for DBUI output buffers
-- Sets up buffer-local options and ensures rainbow syntax is applied

-- Buffer-local options for better table viewing
vim.opt_local.wrap = false -- Don't wrap long lines in tables
vim.opt_local.cursorline = true -- Highlight current row
vim.opt_local.number = false -- No line numbers for cleaner look
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = 'no' -- No sign column
vim.opt_local.list = false -- Hide listchars for cleaner tables
vim.opt_local.scrolloff = 3 -- Keep some context when scrolling

-- Set filetype if not already set
if vim.bo.filetype == '' then
  vim.bo.filetype = 'dbout'
end

-- Ensure syntax highlighting is enabled
vim.opt_local.syntax = 'on'

-- Apply rainbow syntax (main logic is in the plugin config autocmds)
local rainbow = require 'custom.dbui-rainbow'
vim.defer_fn(function()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_is_valid(bufnr) then
    rainbow.apply_syntax(bufnr)
  end
end, 50)

-- Buffer-local keymaps for convenience
local opts = { buffer = true, silent = true }

-- Toggle rainbow style with <leader>dr (DBUI Rainbow)
vim.keymap.set('n', '<leader>dr', ':DBUIToggleRainbowStyle<CR>', vim.tbl_extend('force', opts, { desc = 'Toggle DBUI Rainbow style' }))

-- Show rainbow info with <leader>di (DBUI Info)
vim.keymap.set('n', '<leader>di', ':DBUIRainbowInfo<CR>', vim.tbl_extend('force', opts, { desc = 'Show DBUI Rainbow info' }))

-- Refresh syntax with <leader>dR (DBUI Refresh)
vim.keymap.set('n', '<leader>dR', function()
  local bufnr = vim.api.nvim_get_current_buf()
  rainbow.apply_syntax(bufnr)
  vim.notify('DBUI Rainbow syntax refreshed', vim.log.levels.INFO)
end, vim.tbl_extend('force', opts, { desc = 'Refresh DBUI Rainbow syntax' }))
