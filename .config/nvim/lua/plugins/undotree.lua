return {
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
}
