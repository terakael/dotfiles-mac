return {
  'kristijanhusak/vim-dadbod-ui',
  cmd = { 'DB', 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    {
      'kristijanhusak/vim-dadbod-completion',
      ft = { 'sql', 'mysql', 'plsql' },
      lazy = true,
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  config = function()
    -- Dadbod configuration
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_force_echo_notifications = 1
    vim.g.db_ui_win_position = 'left'
    vim.g.db_ui_winwidth = 30

    -- Connection configuration
    vim.g.dbs = {
      -- Add your connection string here
      -- dev = 'postgresql://user:password@host:port/database',
    }

    -- DBUI Rainbow configuration (see lua/custom/plugins/dbui-rainbow.lua)
    -- Adds rainbow column colors and alternating row backgrounds to query results
    -- Commands: :DBUIToggleRainbowStyle, :DBUISetRainbowStyle, :DBUIRainbowInfo
    -- Buffer keymaps: <leader>dr (toggle), <leader>di (info), <leader>dR (refresh)
    vim.g.dbui_rainbow_enabled = 1
    vim.g.dbui_rainbow_style = 'grid' -- 'grid', 'columns', 'rows', 'off'
    vim.g.dbui_rainbow_max_columns = 20 -- Increased from default 12
  end,
}
