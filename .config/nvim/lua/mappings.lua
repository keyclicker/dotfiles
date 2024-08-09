-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Go to window left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Go to window below' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Go to window above' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Go to window right' })

-- Next and previous buffer
vim.keymap.set('n', '<C-M-n>', '<cmd>bn<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<C-M-p>', '<cmd>bp<CR>', { desc = 'Previous buffer' })

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous Diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next Diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.setloclist, { desc = 'Open diagnostic Quickfix list' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic Error messages' })

-- Toggle diagnostics virtual text
vim.keymap.set('n', '<leader>td', function()
  local prev = vim.diagnostic.config().virtual_text
  local next = not prev
  vim.diagnostic.config { virtual_text = next }
end, { desc = 'Toggle Diagnostics Virtual Text' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Resize windows
vim.keymap.set('n', '<C-Down>', '<cmd>resize -4<CR>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<C-Up>', '<cmd>resize +4<CR>', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -4<CR>', { desc = 'Decrease window width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +4<CR>', { desc = 'Increase window width' })

-- Move in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selected lines down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selected lines up' })

-- Cursor position fixes
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines and keep cursor position' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Move down half page and keep cursor in the center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Move up half page and keep cursor in the center' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Move to next search result and keep cursor in the center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Move to previous search result and keep cursor in the center' })

--Paste fix
vim.keymap.set('x', 'p', '"_dP', { desc = 'Paste without yanking' })
-- Split windows
vim.keymap.set('n', '|', '<cmd>split<CR>', { desc = 'Split window horizontally' })
vim.keymap.set('n', '\\', '<cmd>vsplit<CR>', { desc = 'Split window vertically' })

-- Quickfix list
vim.keymap.set('n', '[q', '<cmd>cprev<CR>', { desc = 'Go to previous Quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<CR>', { desc = 'Go to next Quickfix item' })
-- TODO: lnext / lprev

vim.keymap.set(
  'n',
  '<leader>S',
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = 'Search and replace current word' }
)
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- don't know why, but I will keep it here
vim.keymap.set('n', 'Q', '<nop>', { desc = 'Disable Ex mode' })

-- Stay in indent mode
vim.keymap.set('v', '<S-Tab>', '<gv', { desc = 'Unindent line' })
vim.keymap.set('v', '<Tab>', '>gv', { desc = 'Indent line' })

-----------------------------------------------------------
---                  Keyboard Layouts
-----------------------------------------------------------

vim.keymap.set('n', '<leader>lu', '<cmd>set keymap=ukrainian-enhanced<CR>', { desc = 'Set Ukrainian layout' })
vim.keymap.set('n', '<leader>lr', '<cmd>set keymap=russian-jcukenwin<CR>', { desc = 'Set Russian layout' })
vim.keymap.set('n', '<leader>le', '<cmd>set keymap=<CR>', { desc = 'Set English layout' })

-- vim.opt.iminsert = 0
-- vim.opt.imsearch = 0
