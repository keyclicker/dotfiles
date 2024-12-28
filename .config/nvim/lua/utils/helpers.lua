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
  end
}


