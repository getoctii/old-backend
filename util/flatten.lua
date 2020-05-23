return function(array)
  local new = {}

  for _, parent in ipairs(array) do
    for _, item in ipairs(parent) do
      table.insert(new, item)
    end
  end

  return new
end