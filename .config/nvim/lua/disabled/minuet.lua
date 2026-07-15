return {
  'milanglacier/minuet-ai.nvim',
  event = 'InsertEnter',
  config = function()
    require('minuet').setup {
      virtualtext = {
        -- auto-trigger everywhere, like copilot's suggestion.auto_trigger
        auto_trigger_ft = { '*' },
        auto_trigger_ignore_ft = {},
        keymap = {
          -- copilot-style bindings
          accept = '<C-J>',
          -- accept_line = '<A-a>',
          -- accept_n_lines = '<A-z>',
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
      },

      -- copilot-like responsiveness (local model: guard with small throttle)
      throttle = 100,
      debounce = 50,

      provider = 'openai_fim_compatible',
      n_completions = 3,
      context_window = 2048,
      provider_options = {
        openai_fim_compatible = {
          -- For Windows users, TERM may not be present in environment variables.
          -- Consider using APPDATA instead.
          api_key = 'TERM',
          name = 'Ollama',
          end_point = 'http://127.0.0.1:11434/v1/completions',
          model = 'codegemma:2b',
          -- model = 'codegemma:7b-code',
          optional = {
            max_tokens = 56,
            top_p = 0.9,
            -- stop = { '\n' },
          },
        },
      },
    }
    vim.cmd 'Minuet virtualtext enable'
  end,
  keys = {
    {
      '<leader>zc',
      '<cmd>Minuet virtualtext toggle<cr>',
      desc = 'Toggle Minuet',
    },
  },
}
