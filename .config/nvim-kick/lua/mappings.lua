-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Open netrw explorer
-- vim.keymap.set('n', '<leader>e', '<cmd>Explore<CR>', { desc = 'Open file explorer' })

-- Save and quit
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = 'Write current buffer' })
vim.keymap.set('n', '<leader>W', '<cmd>wall<CR>', { desc = 'Write all buffers' })
vim.keymap.set('n', '<leader>q', '<cmd>q<CR>', { desc = 'Quit current window' })
vim.keymap.set('n', '<leader>Q', '<cmd>qall<CR>', { desc = 'Quit all windows' })
vim.keymap.set('n', '<leader>c', '<cmd>bd<CR>', { desc = 'Close current buffer' })
vim.keymap.set('n', '<leader>C', '<cmd>%bd', { desc = 'Close all buffers' })

-- Neotree

-- Explorer
vim.keymap.set('n', '<leader>E', '<cmd>Exlorer<cr>', { desc = 'Open netrw' })

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

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Resize windows
vim.keymap.set('n', '<C-Up>', '<cmd>resize +4<CR>', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-Down>', '<cmd>resize -4<CR>', { desc = 'Decrease window height' })
vim.keymap.set('n', '<C-Left>', '<cmd>vertical resize +4<CR>', { desc = 'Increase window width' })
vim.keymap.set('n', '<C-Right>', '<cmd>vertical resize -4<CR>', { desc = 'Decrease window width' })

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

vim.keymap.set('n', '<leader>S', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Search and replace current word' })
-- vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- don't know why, but I will keep it here
vim.keymap.set('n', 'Q', '<nop>', { desc = 'Disable Ex mode' })
