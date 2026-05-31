-- Gutter signs for lines with PR comments
local M = {}
local ns = vim.api.nvim_create_namespace 'bitbucket_review'

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  -- Skip non-file buffers
  local bt = vim.bo[bufnr].buftype
  if bt ~= '' then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local pr = require 'bitbucket_review.pr'
  local path = pr.relative_path(bufnr)
  if not path then
    return
  end

  local by_line = pr.state.by_file_line[path]
  if not by_line then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  for line_num, threads in pairs(by_line) do
    if #threads > 0 then
      -- Bitbucket lines are 1-indexed; nvim extmarks are 0-indexed
      local row = line_num - 1
      if row < line_count then
        vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
          sign_text = '💬',
          sign_hl_group = 'DiagnosticInfo',
          priority = 20,
        })
      end
    end
  end
end

function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M
