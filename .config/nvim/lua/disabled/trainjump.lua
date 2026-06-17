-----------------------------------------------------------
---                 Training keymaps
-----------------------------------------------------------

local key_history = {}

local timeout = 1e9

local function throttle_key(key, rev, count)
  count = count or 4

  -- if this is a counted command then don't throttle
  if vim.v.count > 1 then
    vim.cmd('normal! ' .. vim.v.count .. key)
    return
  end

  -- clear all entries that are older than 1 second
  local now = vim.uv.hrtime()
  for i = #key_history, 1, -1 do
    if now - key_history[i][2] > (timeout * count) then
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
  table.insert(key_history, { key, vim.uv.hrtime() })
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
