-- DBUI Rainbow highlighting plugin
-- Adds rainbow column colors and alternating row brightness to DBUI output

return {
  name = 'dbui-rainbow',
  dir = vim.fn.stdpath 'config', -- Use current config directory
  lazy = false, -- Load immediately
  priority = 50, -- Load after colorscheme but before UI

  config = function()
    local rainbow = require 'custom.dbui-rainbow'

    -- Setup with default configuration
    rainbow.setup {
      enabled = vim.g.dbui_rainbow_enabled ~= 0, -- Defaults to true unless explicitly set to 0
      style = vim.g.dbui_rainbow_style or 'grid', -- 'grid', 'columns', 'rows', 'off'
      max_columns = vim.g.dbui_rainbow_max_columns or 20, -- Increased default
      colors = vim.g.dbui_rainbow_colors, -- nil = use Forest theme defaults
    }

    -- Setup highlights on colorscheme change
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = function()
        rainbow.setup_highlights()
      end,
      desc = 'Update DBUI rainbow highlights on colorscheme change',
    })

    -- Auto-apply syntax to DBUI output buffers
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'dbout',
      callback = function(ev)
        -- Delay slightly to ensure buffer is fully loaded
        vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            rainbow.apply_syntax(ev.buf)
          end
        end, 100)
      end,
      desc = 'Apply DBUI rainbow syntax to dbout filetype',
    })

    -- Reapply syntax after buffer content changes
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'TextChanged', 'TextChangedI' }, {
      pattern = '*.dbout',
      callback = function(ev)
        if vim.bo[ev.buf].filetype == 'dbout' then
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
              rainbow.apply_syntax(ev.buf)
            end
          end, 150)
        end
      end,
      desc = 'Reapply DBUI rainbow syntax after content change',
    })

    -- User commands
    vim.api.nvim_create_user_command('DBUIToggleRainbowStyle', function()
      rainbow.toggle_style()
    end, {
      desc = 'Toggle DBUI rainbow style (grid -> columns -> rows -> off)',
    })

    vim.api.nvim_create_user_command('DBUISetRainbowStyle', function(opts)
      rainbow.set_style(opts.args)
    end, {
      nargs = 1,
      complete = function()
        return { 'grid', 'columns', 'rows', 'off' }
      end,
      desc = 'Set DBUI rainbow style',
    })

    vim.api.nvim_create_user_command('DBUIRainbowInfo', function()
      rainbow.show_info()
    end, {
      desc = 'Show DBUI rainbow configuration info',
    })

    -- Optional: Add keybinding to toggle style (uncomment if desired)
    -- vim.keymap.set('n', '<leader>dr', ':DBUIToggleRainbowStyle<CR>', {
    --   desc = 'Toggle DBUI Rainbow style',
    --   silent = true,
    -- })
  end,
}
