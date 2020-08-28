return function(tbl, func)
  local new = {}

  for i, v in ipairs(tbl) do
    if func(v) then
      table.insert(new, v)
    end
  end

  return new
end