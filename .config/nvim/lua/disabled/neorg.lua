return {
  'nvim-neorg/neorg',
  cmd = 'Neorg',
  version = '*', -- Pin Neorg to the latest stable release
  opts = {
    load = {
      ['core.defaults'] = {},
      ['core.concealer'] = {},
      ['core.dirman'] = {
        config = {
          workspaces = {
            notes = '~/notes',
          },
          default_workspace = 'notes',
        },
      },
    },
  },
  keys = {
    {  '<leader>no', '<cmd>Neorg<CR>' },
    {  '<leader>nt', '<cmd>NeorgToggle<CR>' },
  },
}
