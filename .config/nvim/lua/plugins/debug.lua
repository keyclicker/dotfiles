return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-neotest/nvim-nio',
    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local mason_dap = require 'mason-nvim-dap'

    dapui.setup()
    require('dap-go').setup()
    require('dap-python').setup()

    mason_dap.setup {
      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'cppdbg',
        'python',
      },
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,
      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        function(config)
          mason_dap.default_setup(config)
        end,
        cppdbg = function(config)
          config.configurations = {
            {
              name = 'Launch file',
              type = 'cppdbg',
              request = 'launch',
              program = function()
                return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
              end,
              cwd = '${workspaceFolder}',
              stopAtEntry = true,
            },
          }
          mason_dap.default_setup(config)
        end,
      },
    }
    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,

  -- stylua: ignore
  keys = {
    { '<F1>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<F2>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<F3>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F4>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    { '<F5>', function() require('dap').step_back() end, desc = 'Debug: Step Back' },
    { '<F11>', function() require('dap').restart() end, desc = 'Debug: Restart' },
    { '<F12>', function() require('dap').stop() end, desc = 'Debug: Stop' },
    { '<leader>x', function() require('dap').run_to_cursor() end, desc = 'Debug: Run to the Cursor' },
    { '<leader>b', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    { '<F7>', function() require('dapui').toggle() end, desc = 'Debug: See last session result.' },
  },
}
