-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
    {
      '<leader>de',
      function()
        require('dap').set_exception_breakpoints { 'raised', 'uncaught' }
      end,
      desc = 'Debug: Break on all exceptions',
    },
    {
      '<leader>dx',
      function()
        require('dap').set_exception_breakpoints {}
      end,
      desc = 'Debug: Disable exception breakpoints',
    },
    {
      '<leader>dm',
      function()
        -- Maximize current debug window
        vim.cmd 'wincmd o'
      end,
      desc = 'Debug: Maximize current pane',
    },
    {
      '<leader>dr',
      function()
        -- Restore debug UI layout and return focus to code
        require('dapui').close()
        require('dapui').open()
        -- Find and focus the main code window
        local wins = vim.api.nvim_list_wins()
        for _, win in ipairs(wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_buf_get_option(buf, 'filetype')
          -- Focus on non-debug UI windows (your actual code)
          if
            ft ~= 'dapui_watches'
            and ft ~= 'dapui_stacks'
            and ft ~= 'dapui_breakpoints'
            and ft ~= 'dapui_scopes'
            and ft ~= 'dapui_console'
            and ft ~= 'dap-repl'
          then
            vim.api.nvim_set_current_win(win)
            break
          end
        end
      end,
      desc = 'Debug: Restore UI layout',
    },
    {
      '<F8>',
      function()
        require('dap').repl.toggle({}, 'belowright split | resize ' .. math.floor(vim.o.lines * 0.25))
      end,
      desc = 'Debug: Toggle REPL at bottom',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'debugpy',
        'codelldb',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Change breakpoint icons
    -- vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    -- vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    -- local breakpoint_icons = vim.g.have_nerd_font
    --     and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
    --   or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    -- for type, icon in pairs(breakpoint_icons) do
    --   local tp = 'Dap' .. type
    --   local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
    --   vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    -- end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Configure exception breakpoints for Python (only uncaught by default)
    dap.defaults.fallback.exception_breakpoints = { 'uncaught' }

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    -- Python configuration
    dap.adapters.python = function(cb, config)
      if config.request == 'attach' then
        ---@diagnostic disable-next-line: undefined-field
        local port = (config.connect or config).port
        ---@diagnostic disable-next-line: undefined-field
        local host = (config.connect or config).host or '127.0.0.1'
        cb {
          type = 'server',
          port = assert(port, '`connect.port` is required for a python `attach` configuration'),
          host = host,
          options = {
            source_filetype = 'python',
          },
        }
      else
        cb {
          type = 'executable',
          command = 'debugpy-adapter',
          options = {
            source_filetype = 'python',
          },
        }
      end
    end

    -- Rust / C / C++ configuration via codelldb
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = vim.fn.stdpath 'data' .. '/mason/bin/codelldb',
        args = { '--port', '${port}' },
      },
    }

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch with uv run',
        program = '${file}',
        console = 'integratedTerminal',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        justMyCode = false,
        pythonPath = function()
          -- Use uv to find the right python in the project
          local handle = io.popen 'uv run which python 2>/dev/null'
          local result = handle:read '*a'
          handle:close()
          if result and result ~= '' then
            return vim.trim(result)
          end
          -- Fall back to venv or system python
          local venv = os.getenv 'VIRTUAL_ENV'
          if venv then
            return venv .. '/bin/python'
          end
          return vim.fn.exepath 'python3' or vim.fn.exepath 'python' or 'python3'
        end,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file (venv)',
        program = '${file}',
        console = 'integratedTerminal',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        justMyCode = false,
        pythonPath = function()
          -- Check for virtual environment first
          local venv = os.getenv 'VIRTUAL_ENV'
          if venv then
            return venv .. '/bin/python'
          end
          -- Check for .venv in current directory
          local cwd = vim.fn.getcwd()
          local venv_path = cwd .. '/.venv/bin/python'
          if vim.fn.executable(venv_path) == 1 then
            return venv_path
          end
          -- Fall back to system python
          return vim.fn.exepath 'python3' or vim.fn.exepath 'python' or 'python3'
        end,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file with arguments',
        program = '${file}',
        console = 'integratedTerminal',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        justMyCode = false,
        args = function()
          local args_string = vim.fn.input 'Arguments: '
          return vim.split(args_string, ' +')
        end,
        pythonPath = function()
          -- Use uv to find the right python in the project
          local handle = io.popen 'uv run which python 2>/dev/null'
          local result = handle:read '*a'
          handle:close()
          if result and result ~= '' then
            return vim.trim(result)
          end
          local venv = os.getenv 'VIRTUAL_ENV'
          if venv then
            return venv .. '/bin/python'
          end
          return vim.fn.exepath 'python3' or vim.fn.exepath 'python' or 'python3'
        end,
      },
    }
  end,
}
