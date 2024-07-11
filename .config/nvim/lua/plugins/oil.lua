return {
  'stevearc/oil.nvim',
  -- dependencies = { 'echasnovski/mini.icons' },
  dependencies = { 'nvim-tree/nvim-web-devicons' },

  config = function()
    require('oil').setup {
      default_file_explorer = true,
      delete_to_trash = true,

      columns = { 'icon' },
      keymaps = {
        ['<C-h>'] = false,
        ['<C-l>'] = false,
        ['<C-s>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
        ['<C-v>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
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
    }

    vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    vim.keymap.set('n', '_', '<CMD>Oil .<CR>', { desc = 'Open in working directory' })
  end,
}
