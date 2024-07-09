-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    -- { '<leader>e', ':Neotree reveal<CR>', { desc = 'NeoTree reveal' } },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          -- ['<leader>e'] = 'close_window',
        },
      },
    },
  },
  config = function()
    vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<cr>', { desc = 'Toggle neotree' })
    vim.keymap.set('n', '<leader>o', function()
      if vim.bo.filetype == 'neo-tree' then
        vim.cmd.wincmd 'p'
      else
        vim.cmd.Neotree 'focus'
      end
    end)
  end,
}
