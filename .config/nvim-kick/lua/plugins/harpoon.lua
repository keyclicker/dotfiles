return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require 'harpoon'

    -- REQUIRED
    harpoon:setup()
    -- REQUIRED

    vim.keymap.set('n', '<leader>k', function()
      harpoon:list():add()
    end, { desc = 'Na[K]ukanit current buffer' })

    vim.keymap.set('n', '<leader>1', function()
      harpoon:list():select(1)
    end, { desc = 'Open harpoon buffer 1' })
    vim.keymap.set('n', '<leader>2', function()
      harpoon:list():select(2)
    end, { desc = 'Open harpoon buffer 2' })
    vim.keymap.set('n', '<leader>3', function()
      harpoon:list():select(3)
    end, { desc = 'Open harpoon buffer 3' })
    vim.keymap.set('n', '<leader>4', function()
      harpoon:list():select(4)
    end, { desc = 'Open harpoon buffer 4' })
    vim.keymap.set('n', '<leader>5', function()
      harpoon:list():select(5)
    end, { desc = 'Open harpoon buffer 5' })
    vim.keymap.set('n', '<leader>6', function()
      harpoon:list():select(6)
    end, { desc = 'Open harpoon buffer 6' })

    -- Toggle previous & next buffers stored within Harpoon list
    vim.keymap.set('n', '<C-P>', function()
      harpoon:list():prev()
    end)
    vim.keymap.set('n', '<C-N>', function()
      harpoon:list():next()
    end)

    -- basic telescope configuration
    -- local conf = require('telescope.config').values
    -- local function toggle_telescope(harpoon_files)
    --   local file_paths = {}
    --   for _, item in ipairs(harpoon_files.items) do
    --     table.insert(file_paths, item.value)
    --   end
    --
    --   require('telescope.pickers')
    --     .new({}, {
    --       prompt_title = 'Harpoon',
    --       finder = require('telescope.finders').new_table {
    --         results = file_paths,
    --       },
    --       -- previewer = conf.file_previewer {},
    --       sorter = conf.generic_sorter {},
    --     })
    --     :find()
    -- end

    vim.keymap.set('n', '<leader>;', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, {
      desc = 'Open harpoon window',
    })
    -- vim.keymap.set('n', '<M-;>', function()
    --   toggle_telescope(harpoon:list())
    -- end, { desc = 'Open harpoon window' })
  end,
}
