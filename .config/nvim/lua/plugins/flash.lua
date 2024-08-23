return {
  'folke/flash.nvim',
  event = 'VeryLazy',
  ----@type Flash.Config
  opts = {
    modes = {
      char = {
        enabled = false, -- enable after removing smartcase
        multi_line = false,
        char_actions = function()
          return {
            [';'] = 'next',
            [','] = 'prev',
          }
        end,
        highlight = { backdrop = false },
      },
    },
  },
  -- stylua: ignore
  keys = {
    { 's', mode = { 'n', 'x', --[[ 'o' ]] }, function() require('flash').jump() end, desc = 'Flash' },
    { 'S', mode = { 'n', 'x', --[[ 'o' ]] }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
    { 'e', mode = 'o', function() require('flash').remote() end, desc = 'Remote Flash' },
    { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Treesitter Search' },
    { '<c-s>', mode = { 'c' }, function() require('flash').toggle() end, desc = 'Toggle Flash Search' },
  },
}
