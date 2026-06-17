-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- format_on_insert_leave = true
-- vim.api.nvim_create_autocmd('InsertLeave', {
--   desc = 'Format buffer on InsertLeave',
--   group = vim.api.nvim_create_augroup('custom-autoformat', { clear = true }),
--   callback = function()
--     local conform = require 'conform'
--     if format_on_insert_leave and conform then
--       conform.format { async = true, lsp_fallback = true }
--     end
--   end,
-- })
--
-- vim.keymap.set('n', '<leader>tf', function()
--   format_on_insert_leave = not format_on_insert_leave
-- end, { desc = 'Toggle format on InsertLeave' })
