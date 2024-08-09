return {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', event = 'BufReadPre', opts = {}, keys = { { 'gc' } } },

  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    opts = {},
  },

  -- NOTE: Turned off due to the poetry shell bug
  -- {
  --   'christoomey/vim-tmux-navigator',
  --   cmd = {
  --     'TmuxNavigateLeft',
  --     'TmuxNavigateDown',
  --     'TmuxNavigateUp',
  --     'TmuxNavigateRight',
  --     'TmuxNavigatePrevious',
  --   },
  --   keys = {
  --     { '<c-h>', '<cmd><C-U>TmuxNavigateLeft<cr>' },
  --     { '<c-j>', '<cmd><C-U>TmuxNavigateDown<cr>' },
  --     { '<c-k>', '<cmd><C-U>TmuxNavigateUp<cr>' },
  --     { '<c-l>', '<cmd><C-U>TmuxNavigateRight<cr>' },
  --     { '<c-\\>', '<cmd><C-U>TmuxNavigatePrevious<cr>' },
  --   },
  -- },
}
