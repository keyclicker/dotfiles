return {
  {
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.

    opts = {
      on_highlights = function(highlights, colors)
        highlights.LineNr = { fg = '#555F8C' }
        highlights.LineNrAbove = { fg = '#555F8C' }
        highlights.LineNrBelow = { fg = '#555F8C' }
        highlights.CursorLineNr = { bold = true, fg = '#ff966c' }
      end,
    },

    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'tokyonight-moon'
      -- You can configure highlights by doing something like:
      vim.cmd.hi 'Comment gui=none'
    end,
  },
  -- Highlight colors in code
  {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    opts = {
      user_default_options = {
        mode = 'virtualtext',
        virtualtext = '██',
        irtualtext = '██',
        css = true,
        sass = { enable = true, parsers = { 'css' } },
      },
    },
  },
  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = { 'BufReadPost', 'BufWritePost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  -- Lua
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    opts = {
      width = 140, -- width of the Zen window
    },
    keys = {
      { '<leader>z', '<cmd>ZenMode<CR>', desc = 'Toggle Zen Mode' },
    },
  },
}
