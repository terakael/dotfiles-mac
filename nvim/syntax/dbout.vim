" Syntax file for DBUI output buffers
" Provides rainbow column highlighting and alternating row brightness

if exists("b:current_syntax")
  finish
endif

" Use Lua to apply dynamic syntax
lua << EOF
-- Apply rainbow syntax when this syntax file loads
local rainbow = require('custom.dbui-rainbow')
local bufnr = vim.api.nvim_get_current_buf()

-- Apply syntax with a small delay to ensure buffer is ready
vim.defer_fn(function()
  if vim.api.nvim_buf_is_valid(bufnr) then
    rainbow.apply_syntax(bufnr)
  end
end, 10)
EOF

let b:current_syntax = "dbout"
