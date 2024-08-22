-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Go to window left' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Go to window below' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Go to window above' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Go to window right' })

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

-- Toggle virtual editing
vim.opt.virtualedit = 'block'
vim.keymap.set('n', '<leader>zv', function()
  if vim.o.virtualedit == 'block' then
    vim.opt.virtualedit = 'all'
  else
    vim.opt.virtualedit = 'block'
  end
end, { desc = 'Toggle Virtual Edit' })

-----------------------------------------------------------
---                  Keyboard Layouts
-----------------------------------------------------------

vim.keymap.set('n', '<leader>lu', '<cmd>set keymap=ukrainian-enhanced<CR>', { desc = 'Set Ukrainian layout' })
vim.keymap.set('n', '<leader>lr', '<cmd>set keymap=russian-jcukenwin<CR>', { desc = 'Set Russian layout' })
vim.keymap.set('n', '<leader>le', '<cmd>set keymap=<CR>', { desc = 'Set English layout' })

-- vim.opt.iminsert = 0
-- vim.opt.imsearch = 0

-----------------------------------------------------------
---                 Training keymaps
-----------------------------------------------------------

local key_history = {}

local count = 5
local timeout = 2e9

local function throttle_key(key, rev)
  -- if this is a counted command then don't throttle
  if vim.v.count > 1 then
    vim.cmd('normal! ' .. vim.v.count .. key)
    return
  end

  -- clear all entries that are older than 1 second
  local now = vim.loop.hrtime()
  for i = #key_history, 1, -1 do
    if now - key_history[i][2] > timeout then
      table.remove(key_history, i)
    end
  end

  -- check if the last `count` keys are the same
  if #key_history >= count then
    local diff = false
    for i = 1, count do
      if key_history[#key_history - i + 1][1] ~= key then
        vim.cmd('normal! ' .. key)
        diff = true
        break
      end
    end
    if rev and not diff then
      vim.cmd('normal! ' .. count .. rev)
      key_history = {}
      return
    end
  -- if <`count` then there is fidgeting, so just do the key
  else
    vim.cmd('normal! ' .. key)
  end

  -- memorize the key
  table.insert(key_history, { key, vim.loop.hrtime() })
end

-- stylua: ignore
if true then
  vim.keymap.set('n', 'j', function() throttle_key( 'j', 'k') end)
  vim.keymap.set('n', 'k', function() throttle_key( 'k', 'j') end)
  vim.keymap.set('n', 'h', function() throttle_key( 'h', 'l') end)
  vim.keymap.set('n', 'l', function() throttle_key( 'l', 'h') end)
  vim.keymap.set('n', 'w', function() throttle_key( 'w', 'b') end)
  vim.keymap.set('n', 'b', function() throttle_key( 'b', 'w') end)
  vim.keymap.set('n', 'e', function() throttle_key( 'e', 'ge') end)
  vim.keymap.set('n', 'W', function() throttle_key( 'W', 'B') end)
  vim.keymap.set('n', 'B', function() throttle_key( 'B', 'W') end)
  vim.keymap.set('n', 'E', function() throttle_key( 'E', 'W') end)
  vim.keymap.set('n', '{', function() throttle_key( '{', '}') end)
  vim.keymap.set('n', '}', function() throttle_key( '}', '{') end)
end
