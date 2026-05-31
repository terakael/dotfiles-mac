return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  lazy = false,
  ---@type rustaceanvim.Opts
  opts = {
    server = {
      on_attach = function(client, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
        end
        -- Override global K and <leader>ca with Rust-enhanced versions
        map('K', function()
          vim.cmd.RustLsp { 'hover', 'actions' }
        end, 'Hover Actions')
        map('<leader>ca', function()
          vim.cmd.RustLsp 'codeAction'
        end, 'Code Action')
        -- Rust-specific commands under <leader>R
        map('<leader>Rd', function()
          vim.cmd.RustLsp 'debuggables'
        end, 'Debuggables')
        map('<F5>', function()
          local dap = require 'dap'
          if dap.session() then
            dap.continue()
          else
            vim.cmd.RustLsp 'debuggables'
          end
        end, 'Debug')
        map('<leader>Rr', function()
          vim.cmd.RustLsp 'runnables'
        end, 'Runnables')
        map('<leader>Re', function()
          vim.cmd.RustLsp 'expandMacro'
        end, 'Expand Macro')
        map('<leader>Rc', function()
          vim.cmd.RustLsp 'openCargo'
        end, 'Open Cargo.toml')
        map('<leader>cc', function()
          vim.cmd 'compiler cargo'
          vim.cmd 'silent make! check'
          vim.cmd 'copen'
        end, 'Cargo Check')
      end,
    },
    dap = {
      adapter = {
        type = 'server',
        port = '${port}',
        executable = {
          command = vim.fn.stdpath 'data' .. '/mason/bin/codelldb',
          args = { '--port', '${port}' },
        },
      },
    },
  },
  config = function(_, opts)
    vim.g.rustaceanvim = opts
  end,
}
