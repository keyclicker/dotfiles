vim.opt.foldmethod = 'indent'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

return {
  -- 'kevinhwang91/nvim-ufo',
  -- dependencies = { 'kevinhwang91/promise-async' },
  -- event = 'BufReadPre',
  -- opts = {
  --   provider_selector = function()
  --     return { 'treesitter', 'indent' }
  --   end,
  -- },
  --
  -- config = function(opts)
  --   require('ufo').setup(opts)
  --
  --   vim.opt.foldcolumn = '0' -- '0' is not bad
  --   vim.opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
  --   vim.opt.foldlevelstart = 99
  --   vim.opt.foldenable = true
  -- end,
  --
  -- -- stylua: ignore
  -- -- keys = {
  -- --   { 'zR', function() require('ufo').openAllFolds() end },
  -- --   { 'zM', function() require('ufo').closeAllFolds() end },
  -- -- },
}
