return {
  {
    'andythigpen/nvim-coverage',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'Coverage', 'CoverageShow', 'CoverageHide', 'CoverageToggle', 'CoverageSummary' },
    opts = {
      commands = true, -- create commands
      auto_reload = true,
      auto_reload_time = 1000,

      highlights = {
        -- customize highlight groups created by the plugin
        covered = { fg = '#C3E88D' }, -- supports style, fg, bg, sp (see :h highlight-gui)
        uncovered = { fg = '#F07178' },
        partial = { fg = '#FFCB6B' },
      },
      signs = {
        -- use your own highlight groups or text markers
        covered = { hl = 'CoverageCovered', text = 'C', priority = 10 },
        uncovered = { hl = 'CoverageUncovered', text = 'U', priorit = 10 },
        partial = { hl = 'CoveragePartiallyCovered', text = 'P', priority = 10 },
      },
      summary = {
        -- customize the summary pop-up
        min_coverage = 80.0, -- minimum coverage threshold (used for highlighting)
      },
      lang = {
        -- customize language specific settings
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>uc', function () require('nvim-coverage').load({place=true})end , desc = 'Load Coverage' },
      { '<leader>ut', function() require('nvim-coverage').toggle() end, desc = 'Toggle Coverage Signs' },
      { '<leader>uC', function () require('nvim-coverage').summary() end, desc = 'Display Coverrage Summary' },
    },
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-go',
      'nvim-neotest/neotest-jest',
      'nvim-neotest/neotest-python',
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        adapters = {
          require 'neotest-go',
          require 'neotest-jest' {
            jestCommand = 'npm run test',
            jestConfigFile = 'jest.config.ts',
            env = { CI = true },
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          },
          require 'neotest-python' {
            -- Extra arguments for nvim-dap configuration
            -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
            dap = { justMyCode = false },
            -- Command line arguments for runner
            -- Can also be a function to return dynamic values
            args = { '--log-level', 'DEBUG' },
            -- Runner to use. Will use pytest if available by default.
            -- Can be a function to return dynamic value.
            runner = 'pytest',
            -- Custom python path for the runner.
            -- Can be a string or a list of strings.
            -- Can also be a function to return dynamic value.
            -- If not provided, the path will be inferred by checking for
            -- virtual envs in the local directory and for Pipenev/Poetry configs
            python = '.venv/bin/python',
            -- Returns if a given file path is a test file.
            -- NB: This function is called a lot so don't perform any heavy tasks within it.
            -- is_test_file = function(file_path)
            --   ...
            -- end,
            -- !!EXPERIMENTAL!! Enable shelling out to `pytest` to discover test
            -- instances for files containing a parametrize mark (default: false)
            pytest_discover_instances = true,
          },
        },
      }
    end,

    -- stylua: ignore
    keys = {
      { "<leader>uf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
      { "<leader>uF", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files" },
      { "<leader>un", function() require("neotest").run.run() end, desc = "Run Nearest" },
      { "<leader>ur", function() require("neotest").run.run_last() end, desc = "Run Resent" },
      { "<leader>us", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
      { "<leader>uo", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output" },
      { "<leader>uO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
      { "<leader>uS", function() require("neotest").run.stop() end, desc = "Stop" },
      { "<leader>uw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch" },
      { '<leader>ud', function() require("neotest").run.run({strategy = "dap"}) end, desc = 'Debug Nearest'},
      { '<leader>ua', function() require("neotest").run.attach() end, desc = 'Attach Nearest'},
    },
  },
}
