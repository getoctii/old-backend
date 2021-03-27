return function(str)
  return str:gsub('[%%_]', '\\%1')
end