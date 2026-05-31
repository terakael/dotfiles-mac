-- Source .nvim.lua by walking up from each opened buffer's directory.
-- Uses vim.secure.read() for the same trust-prompt security as exrc,
-- but works regardless of what directory Neovim was started from.
local sourced_nvim_configs = {}
vim.api.nvim_create_autocmd('BufRead', {
  callback = function()
    local dir = vim.fn.expand '%:p:h'
    while true do
      local candidate = dir .. '/.nvim.lua'
      if vim.fn.filereadable(candidate) == 1 then
        if not sourced_nvim_configs[candidate] then
          local content = vim.secure.read(candidate)
          if content then
            load(content, '@' .. candidate)()
            sourced_nvim_configs[candidate] = true
          end
        end
        break
      end
      local parent = vim.fn.fnamemodify(dir, ':h')
      if parent == dir then
        break
      end
      dir = parent
    end
  end,
})

-- Auto-create pyrightconfig.json if .venv exists but pyrightconfig doesn't
vim.api.nvim_create_autocmd({ 'VimEnter', 'DirChanged' }, {
  desc = 'Auto-create pyrightconfig.json for .venv projects',
  group = vim.api.nvim_create_augroup('auto-pyrightconfig', { clear = true }),
  callback = function()
    local cwd = vim.fn.getcwd()
    local venv_path = cwd .. '/.venv'
    local pyright_config = cwd .. '/pyrightconfig.json'

    -- Check if .venv exists and pyrightconfig.json doesn't
    if vim.fn.isdirectory(venv_path) == 1 and vim.fn.filereadable(pyright_config) == 0 then
      local config_content = vim.json.encode {
        venvPath = '.',
        venv = '.venv',
      }
      local file = io.open(pyright_config, 'w')
      if file then
        file:write(config_content)
        file:close()
      end
    end
  end,
})

-- Auto-reload buffers when files change externally
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave', 'CursorHold', 'CursorHoldI' }, {
  desc = 'Check for file changes and reload buffer if unchanged',
  group = vim.api.nvim_create_augroup('auto-reload', { clear = true }),
  callback = function()
    if vim.o.buftype ~= 'nofile' then
      vim.cmd 'checktime'
    end
  end,
})

-- Detect Helm template files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  desc = 'Set filetype for Helm template files',
  group = vim.api.nvim_create_augroup('helm-filetype', { clear = true }),
  pattern = { '*/templates/*.yaml', '*/templates/*.tpl', 'helmfile.yaml' },
  callback = function()
    vim.bo.filetype = 'helm'
  end,
})

-- Enable line wrapping for markdown and text files
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Enable line wrapping for document files',
  group = vim.api.nvim_create_augroup('wrap-documents', { clear = true }),
  pattern = { 'markdown', 'text' },
  callback = function()
    vim.opt_local.wrap = true
  end,
})
