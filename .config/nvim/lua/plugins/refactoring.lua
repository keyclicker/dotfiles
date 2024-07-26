return {
  'ThePrimeagen/refactoring.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {},
  keys = {
    {
      '<leader>R',
      function()
        require('telescope').extensions.refactoring.refactors()
      end,
      mode = { 'n', 'x' },
      desc = 'Refactor',
    },
  },
}
