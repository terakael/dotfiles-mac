-- Bitbucket PR review plugin (local module, no external package)
-- Modules live in lua/bitbucket_review/
-- Requires: folke/snacks.nvim (already loaded), BITBUCKET_BEARER_TOKEN env var

vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    local ok, err = pcall(require('bitbucket_review').setup)
    if not ok then
      vim.notify('[BbReview] Setup error: ' .. tostring(err), vim.log.levels.ERROR)
    end
  end,
})

return {}
