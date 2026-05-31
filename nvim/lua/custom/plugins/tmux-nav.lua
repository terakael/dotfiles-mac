return {
  'tmux-nav',
  virtual = true,
  lazy = false,
  config = function()
    if not vim.env.TMUX then
      return
    end

    local tmux_socket = vim.split(vim.env.TMUX, ',')[1]
    local function tmux(args)
      local handle
      handle = vim.uv.spawn('tmux', { args = vim.list_extend({ '-S', tmux_socket }, args) }, function()
        handle:close()
      end)
    end

    local pane_dir = { h = 'L', j = 'D', k = 'U', l = 'R' }
    local function navigate(dir)
      local before = vim.fn.winnr()
      vim.cmd('wincmd ' .. dir)
      if vim.fn.winnr() == before then
        tmux { 'select-pane', '-Z' .. pane_dir[dir] }
      end
    end

    for _, dir in ipairs { 'h', 'j', 'k', 'l' } do
      vim.keymap.set('n', '<C-' .. dir .. '>', function()
        navigate(dir)
      end)
    end

    vim.api.nvim_create_autocmd({ 'VimEnter', 'FocusGained' }, {
      callback = function()
        tmux { 'set', '-p', '@pane-is-vim', '1' }
      end,
    })
    vim.api.nvim_create_autocmd({ 'VimLeave', 'FocusLost' }, {
      callback = function()
        tmux { 'set', '-p', '@pane-is-vim', '0' }
      end,
    })
    tmux { 'set', '-p', '@pane-is-vim', '1' }
  end,
}
