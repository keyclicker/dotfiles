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
        -- ['<M-h>'] = 'actions.select_split',
      },
      view_options = {
        show_hidden = true,
      },
    }

    vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })
    vim.keymap.set('n', '_', '<CMD>Oil .<CR>', { desc = 'Open in working directory' })
  end,
}
