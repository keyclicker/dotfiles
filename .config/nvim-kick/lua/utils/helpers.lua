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
}
