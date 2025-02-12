return {
  ---@param table1 table
  ---@param table2 table
  merge = function(table1, table2)
    local merged = {}
    for k, v in pairs(table1) do
      merged[k] = v
    end
    for k, v in pairs(table2) do
      merged[k] = v
    end
    return merged
  end,

  ---@param ms number
  ---@param fn function
  debounce = function(ms, fn)
    local timer = vim.uv.new_timer()
    return function(...)
      local argv = { ... }
      timer:start(ms, 0, function()
        timer:stop()
        vim.schedule_wrap(fn)(unpack(argv))
      end)
    end
  end,

  ---@param t table
  ---@param fn function
  -- Filter in place
  -- https://stackoverflow.com/questions/49709998/how-to-filter-a-lua-array-inplace
  filter_inplace = function(t, fn)
    local new_index = 1
    local size_orig = #t
    for old_index, v in ipairs(t) do
      if fn(v, old_index) then
        t[new_index] = v
        new_index = new_index + 1
      end
    end
    for i = new_index, size_orig do
      t[i] = nil
    end
  end,
}
