return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    settings = {
      save_on_toggle = true,
      key = function()
        return vim.loop.cwd() .. '::tab=' .. vim.api.nvim_get_current_tabpage()
      end,
    },
  },
  keys = function()
    local keys = {
      {
        '<leader>k',
        function()
          require('harpoon'):list():add()
        end,
        desc = 'Na[K]ukanit Current Buffer',
      },
      {
        '<leader>;',
        function()
          local harpoon = require 'harpoon'
          harpoon.ui:toggle_quick_menu(harpoon:list(), { ui_max_width = 80 })
        end,
        desc = 'Harpoon Quick Menu',
      },
    }

    for i = 1, 6 do
      table.insert(keys, {
        '<leader>' .. i,
        function()
          require('harpoon'):list():select(i)
        end,
        -- desc = "Harpoon to File " .. i,
        desc = 'which_key_ignore',
      })
    end
    return keys
  end,
}
