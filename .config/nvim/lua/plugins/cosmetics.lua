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

    -- Follow the terminal, not the OS: over ssh the OS is the remote
    -- box, but the colors are the local terminal's. Nvim asks the
    -- terminal (OSC 11, answered by tmux for the attached client) and
    -- sets 'background'; pick the matching style. Plain `tokyonight`
    -- would force 'background' back to its own style instead.
    init = function()
      local function apply()
        local light = vim.o.background == 'light'
        vim.cmd.colorscheme(light and 'tokyonight-day' or 'tokyonight-moon')
      end

      local group = vim.api.nvim_create_augroup('terminal-theme', {})

      vim.api.nvim_create_autocmd('OptionSet', {
        group = group,
        pattern = 'background',
        callback = apply,
      })

      -- Re-ask on focus: catches the terminal switching light/dark
      vim.api.nvim_create_autocmd('FocusGained', {
        group = group,
        callback = function()
          vim.api.nvim_ui_send '\027]11;?\007'
        end,
      })

      apply()
    end,
  },
}
