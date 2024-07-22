return {
  'stevearc/oil.nvim',
  cmd = { 'Oil' },
  event = 'VeryLazy',
  lazy = false,
  -- dependencies = { 'echasnovski/mini.icons' },
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,

    columns = { 'icon' },
    keymaps = {
      ['<C-h>'] = false,
      ['<C-l>'] = false,
      -- ['<C->'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
      ['<C-s>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
      ['<C-c>'] = 'actions.refresh',
    },
    win_options = {
      winbar = "%{v:lua.require('oil').get_current_dir()}",
    },
    view_options = {
      show_hidden = true,
      natural_order = true,
      is_always_hidden = function(name, _)
        return name == '.git'
          or name == '.DS_Store'
          or name == '__pycache__'
          or name == '.mypy_cache'
          or name == '.pytest_cache'
          or name == '.idea'
          or name == '.VSCodeCounter'
          or name == '.next'
          or name == 'coverage'
          or name == 'node_modules'
          or name == 'tsconfig.tsbuildinfo'
      end,
    },
  },
  keys = {
    { '-', '<CMD>Oil<CR>', desc = 'Open parent directory' },
    { '_', '<CMD>Oil .<CR>', desc = 'Open in working directory' },
  },
}
