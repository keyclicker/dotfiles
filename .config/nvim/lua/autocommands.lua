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

-- TODO(to-delete): remove if no longer needed
-- Close CodeDiff tabs before persistence writes the session, so restore
-- doesn't leave a dead blank tab (codediff:// buffers can't reload). Mirrors
-- how Neogit drops its buffers before quit. Fires on persistence's SavePre,
-- which runs on VimLeavePre right before :mksession.
vim.api.nvim_create_autocmd('User', {
  pattern = 'PersistenceSavePre',
  group = vim.api.nvim_create_augroup('codediff-session-close', { clear = true }),
  callback = function()
    local ok, lifecycle = pcall(require, 'codediff.ui.lifecycle')
    if not ok then
      return
    end
    -- Collect first; closing tabs mutates the tabpage list.
    local tabs = {}
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      if lifecycle.get_session(tab) then
        table.insert(tabs, tab)
      end
    end
    for _, tab in ipairs(tabs) do
      pcall(lifecycle.cleanup_for_quit, tab) -- wipe the diff/scratch buffers
      if vim.api.nvim_tabpage_is_valid(tab) and #vim.api.nvim_list_tabpages() > 1 then
        vim.api.nvim_set_current_tabpage(tab)
        pcall(vim.cmd, 'tabclose')
      end
    end
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
