return function(tbl, func)
  local new = {}

  for i, v in ipairs(tbl) do
    table.insert(new, func(v))
  end

  return new
end