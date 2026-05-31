return {
  'NickvanDyke/opencode.nvim',
  dependencies = {
    'folke/snacks.nvim',
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition".
    }

    -- Required for `opts.auto_reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.

    local opencode = require 'opencode'

    vim.keymap.set({ 'n', 'x' }, '<C-x>a', function()
      opencode.ask()
    end, { desc = 'OpenCode: [A]sk (input dialog)' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>s', function()
      opencode.select()
    end, { desc = 'OpenCode: [S]elect action' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>x', function()
      opencode.prompt('explain', { submit = true })
    end, { desc = 'OpenCode: E[x]plain this' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>c', function()
      opencode.prompt('document', { submit = true })
    end, { desc = 'OpenCode: Do[c]ument' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>e', function()
      opencode.prompt('diagnostics', { submit = true })
    end, { desc = 'OpenCode: [E]xplain diagnostics' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>f', function()
      opencode.prompt('fix', { submit = true })
    end, { desc = 'OpenCode: [F]ix diagnostics' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>o', function()
      opencode.prompt('optimize', { submit = true })
    end, { desc = 'OpenCode: [O]ptimize' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>r', function()
      opencode.prompt('review', { submit = true })
    end, { desc = 'OpenCode: [R]eview' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>t', function()
      opencode.prompt('test', { submit = true })
    end, { desc = 'OpenCode: [T]est' })

    vim.keymap.set({ 'n', 'x' }, '<C-x>d', function()
      opencode.prompt('diff', { submit = true })
    end, { desc = 'OpenCode: [D]iff' })
  end,
}
