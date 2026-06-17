-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- don't know why, but I will keep it here
vim.keymap.set('n', 'Q', '<nop>', { desc = 'Disable Ex mode' })

-- Window navigation
-- vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Go to window left' })
-- vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Go to window below' })
-- vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Go to window above' })
-- vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Go to window right' })

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.setloclist, { desc = 'Open diagnostic Quickfix list' })
vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Show diagnostic Error messages' })

-- Toggle diagnostics virtual text
vim.keymap.set('n', '<leader>zd', function()
  local prev = vim.diagnostic.config().virtual_text
  local next = not prev
  vim.diagnostic.config { virtual_text = next }
end, { desc = 'Toggle Diagnostics Virtual Text' })

-- Resize windows
vim.keymap.set('n', '<C-Down>', '<cmd>resize -4<CR>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<C-Up>', '<cmd>resize +4<CR>', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize -4<CR>', { desc = 'Decrease window width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize +4<CR>', { desc = 'Increase window width' })

-- Move in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selected lines down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selected lines up' })
vim.keymap.set('v', 'H', '<gv', { desc = 'Unindent line' })
vim.keymap.set('v', 'L', '>gv', { desc = 'Indent line' })

-- Cursor position fixes
vim.keymap.set('n', 'J', 'mzJ`z', { desc = 'Join lines and keep cursor position' })
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Move down half page and keep cursor in the center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Move up half page and keep cursor in the center' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Move to next search result and keep cursor in the center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Move to previous search result and keep cursor in the center' })

-- Quickfix list
vim.keymap.set('n', '[q', '<cmd>cprev<CR>', { desc = 'Go to previous Quickfix item' })
vim.keymap.set('n', ']q', '<cmd>cnext<CR>', { desc = 'Go to next Quickfix item' })
vim.keymap.set('n', '[l', '<cmd>lnext<CR>', { desc = 'Go to previous Location list item' })
vim.keymap.set('n', ']l', '<cmd>lprev<CR>', { desc = 'Go to next Location list item' })

vim.keymap.set(
  'n',
  '<leader>S',
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = 'Search and replace current word' }
)

-- Execute keymaps
vim.keymap.set('n', '<leader>xc', '<cmd>!chmod +x %<CR>', { silent = true, desc = 'Make file executable' })
vim.keymap.set('n', '<leader>xr', '<cmd>!chmod -x %<CR>', { silent = true, desc = 'Make file non-executable' })

-- Keyboard layout
vim.keymap.set('n', '<leader>lu', '<cmd>set keymap=ukrainian-enhanced<CR>', { desc = 'Set Ukrainian layout' })
vim.keymap.set('n', '<leader>lr', '<cmd>set keymap=russian-jcukenwin<CR>', { desc = 'Set Russian layout' })
vim.keymap.set('n', '<leader>le', '<cmd>set keymap=<CR>', { desc = 'Set English layout' })
-- vim.opt.iminsert = 0
-- vim.opt.imsearch = 0

-- Toggle virtual editing
vim.opt.virtualedit = 'block'
vim.keymap.set('n', '<leader>zv', function()
  if vim.o.virtualedit == 'block' then
    vim.opt.virtualedit = 'all'
  else
    vim.opt.virtualedit = 'block'
  end
end, { desc = 'Toggle Virtual Edit' })

-- Pasting fix
vim.keymap.set('i', '<C-r>', '<C-r><C-p>', { noremap = true })

-- tshell style keymaps
vim.keymap.set({ 'c', 'i' }, '<C-F>', '<Right>', { noremap = true, desc = 'Go to right' })
vim.keymap.set({ 'c', 'i' }, '<C-B>', '<Left>', { noremap = true, desc = 'Go to left' })

vim.keymap.set('i', '<C-A>', '<C-O>^', { noremap = true, desc = 'Go to beginning of line' })
vim.keymap.set('i', '<C-E>', '<End>', { noremap = true, desc = 'Go to end of line' })

vim.keymap.set('c', '<C-A>', '<Home>', { noremap = true, desc = 'Go to beginning of line' })
