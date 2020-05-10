local bit = require 'bit'
local rand = require 'openssl.rand'

local function hexlist(input)
  local array = {}

  for _, num in ipairs(input) do
    table.insert(array, bit.tohex(num, 2))
  end

  return array
end

local function bytelist(str)
  local array = {}

  for char in string.gmatch(str, '.') do
    table.insert(array, string.byte(char))
  end

  return array
end

return function()
  local random, err = rand.bytes(16)
  if not random then
    return nil, err
  end

  local bytes = bytelist(random)
  bytes[7] = bit.bor(bit.band(bytes[7], 0x0f), 0x40)
  bytes[9] = bit.bor(bit.band(bytes[9], 0x3f), 0x80)
  return string.format('%s%s%s%s-%s%s-%s%s-%s%s-%s%s%s%s%s%s', unpack(hexlist(bytes)))
end
