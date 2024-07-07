return {

  {
    -- Theme inspired by Atom
    'folke/tokyonight.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      require('tokyonight').setup {
        style = 'moon',
      }
      require('tokyonight').load()
    end,
  },

  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'auto',
        component_separators = '|',
        section_separators = '',
      },
    },

    config = function()
      require('lualine').setup {
        options = {
          theme = 'tokyonight',
        },
      }
    end,
  },
}
