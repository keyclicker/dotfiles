-- NOTE: Plugins can specify dependencies.
--
-- The dependencies are proper plugin specifications as well - anything
-- you do for a plugin at the top level, you can do for a dependency.
--
-- Use the `dependencies` key to specify the dependencies of a particular plugin

return {
  { -- Autoformat
    'stevearc/conform.nvim',
    event = { 'BufWritePre' }, -- arms format_on_save before the first save
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>j',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = {
        timeout_ms = 3000,
        lsp_fallback = false,
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        -- Conform can also run multiple formatters sequentially
        python = { 'isort', 'black' },
        --
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        -- javascript = { {'prettier', 'prettierd' }},

        markdown = { 'markdownlint' },
        javascript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescript = { 'prettierd' },
        typescriptreact = { 'prettierd' },

        css = { 'prettierd' },
        scss = { 'prettierd' },
        html = { 'prettierd' },
        json = { 'prettierd' },

        cpp = { 'clang-format' },
        c = { 'clang-format' },

        go = { 'gofmt', 'gofumpt' },

        -- sh = { 'shfmt' },
        -- bash = { 'shfmt' },
        -- zsh = { 'shfmt' },

        -- tex = { 'tex-fmt' },
      },
    },
  },
  { -- Linting
    'mfussenegger/nvim-lint',
    event = 'LazyFile',
    opts = {
      events = { 'BufReadPost', 'BufWritePost' }, --'InsertLeave' },

      linters_by_ft = {
        markdown = { 'markdownlint' },
        python = { 'pylint', 'mypy', 'flake8' },

        scss = { 'stylelint' },
        css = { 'stylelint' },
        json = { 'jsonlint' },

        cpp = { 'cpplint' },
        c = { 'cpplint' },
      },
    },
    config = function(_, opts)
      local lint = require 'lint'
      lint.linters_by_ft = opts.linters_by_ft

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd(opts.events, {
        group = lint_augroup,
        callback = require('utils.helpers').debounce(100, function()
          lint.try_lint()
        end),
      })
    end,
  },
}
