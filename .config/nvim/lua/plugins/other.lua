return {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  {
    'folke/ts-comments.nvim',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    opts = {},
  },
  {
    'echasnovski/mini.nvim',
    version = false,
    config = function()
      require('mini.bufremove').setup()
    end,

    keys = {
      {
        '<leader>c',
        function()
          MiniBufremove.delete()
        end,
        mode = 'n',
        desc = 'Delete buffer',
      },
    },
  },
  {
    'christoomey/vim-tmux-navigator',
    cmd = {
      'TmuxNavigateLeft',
      'TmuxNavigateDown',
      'TmuxNavigateUp',
      'TmuxNavigateRight',
      'TmuxNavigatePrevious',
    },
    keys = {
      { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
      { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
      { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
      { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
      { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
    },
  },
  {
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    config = function()
      vim.g.undotree_SplitWidth = 40
      vim.g.undotree_DiffpanelHeight = 20
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
    keys = {
      { '<leader>u', '<cmd>UndotreeToggle<CR>', desc = 'Undotree toggle' },
    },
  },
  {
    {
      'folke/persistence.nvim',
      event = 'BufReadPre',
      opts = {},
    -- stylua: ignore
    keys = {
      { '<leader>mm', function() require('persistence').load() end, desc = 'Restore session' },
      { '<leader>ms', function() require('persistence').select() end, desc = 'Select session' },
      { '<leader>ml', function() require('persistence').load({ last = true }) end, desc = 'Restore last session' },
      { '<leader>md', function() require('persistence').stop() end, desc = "Don't save current session" },
    },
    },
  },
  {
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
  },
  {
    'ThePrimeagen/vim-be-good',
    cmd = { 'VimBeGood' },
  },
}
