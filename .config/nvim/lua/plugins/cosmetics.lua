return {
  -- Highlight colors in code
  {
    'NvChad/nvim-colorizer.lua',
    event = 'LazyFile',
    opts = {
      user_default_options = {
        mode = 'virtualtext',
        virtualtext = '██',
        css = true,
        sass = { enable = true, parsers = { 'css' } },
      },
    },
  },
  -- Highlight todo, notes, etc in comments
  {
    'folke/todo-comments.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = 'LazyFile',
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
      { '<leader>zz', '<cmd>ZenMode<CR>', desc = 'Toggle Zen Mode' },
    },
  },

  ---------------------------------------------------------
  ---                   Colorschemes
  ---------------------------------------------------------
  {
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.

    opts = {
      on_highlights = function(highlights, colors)
        highlights.LineNr = { fg = '#555F8C' }
        highlights.LineNrAbove = { fg = '#555F8C' }
        highlights.LineNrBelow = { fg = '#555F8C' }
        highlights.CursorLineNr = { bold = true, fg = '#ff966c' }
        highlights.EndOfBuffer = { fg = '#555F8C' }

        -- Make intra-line diff (DiffText) visible under the transparent theme
        highlights.DiffChange = { bg = '#2a3760' }
        highlights.DiffText = { bg = '#3c5aa4', bold = true }
        -- Dim codediff's ╱ filler further (default #444444)
        highlights.CodeDiffFiller = { fg = '#333333' }
      end,
      light_style = 'day',
      transparent = true,
      styles = {
        sidebars = 'transparent',
        floats = 'transparent',
      },
    },

    init = function()
      vim.cmd.colorscheme 'tokyonight-moon'
    end,
  },

  {
    'f-person/auto-dark-mode.nvim',
    -- Polls the OS theme; a guest reached over ssh has none.
    enabled = not vim.g.minimal,
    opts = {
      update_interval = 1000,
      fallback = 'dark',
      set_dark_mode = function()
        vim.o.background = 'dark'
        vim.cmd.colorscheme 'tokyonight-moon'
      end,
      set_light_mode = function()
        vim.o.background = 'light'
        vim.cmd.colorscheme 'tokyonight-day'
      end,
    },
  },
}
