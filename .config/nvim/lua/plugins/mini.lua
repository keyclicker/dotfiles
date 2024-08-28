return {
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
}
