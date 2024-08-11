return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  opts = {
    panel = {
      enabled = true,
      auto_refresh = false,
      keymap = {
        jump_prev = '[[',
        jump_next = ']]',
        accept = '<CR>',
        refresh = 'gr', -- NOTE: conflict
        open = '<M-CR>',
      },
      layout = {
        position = 'right', -- | top | left | right
        ratio = 0.4,
      },
    },
    suggestion = {
      enabled = true,
      auto_trigger = true,
      debounce = 75,
      keymap = {
        accept = '<C-y>',
        accept_word = false,
        accept_line = false,
        next = '<M-]>',
        prev = '<M-[>',
        dismiss = '<C-]>',
      },
    },
    filetypes = {
      -- yaml = false,
      markdown = true,
      -- help = false,
      -- gitcommit = false,
      -- gitrebase = false,
      -- hgcommit = false,
      -- svn = false,
      -- cvs = false,
      ['.'] = true,
    },
    copilot_node_command = 'node', -- Node.js version must be > 18.x
    server_opts_overrides = {},
  },
  keys = {
    {
      '<leader>tc',
      function()
        require('copilot.suggestion').toggle_auto_trigger()
      end,
      desc = 'Toggle Copilot',
    },
  },
}
