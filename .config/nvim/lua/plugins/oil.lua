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
      case_insensitive = false,
      sort = {
        { 'type', 'asc' },
        { 'name', 'asc' },
      },
      is_always_hidden = function(name, _)
        return name == '.DS_Store'
      end,
    },
    git = {
      -- Return true to automatically git add/mv/rm files
      add = function(path)
        return true
      end,
      mv = function(src_path, dest_path)
        return true
      end,
      rm = function(path)
        return true
      end,
    },
  },
  keys = {
    { '-', '<CMD>Oil<CR>', desc = 'Open parent directory' },
    { '_', '<CMD>Oil .<CR>', desc = 'Open in working directory' },
  },
}
