local Users = require 'models.users'

local function generateDiscriminator(username)
  local num = Users:count('username = ?', username)
  if num >= 9999 then return false, { 400, 'InvalidDiscriminator' } end
  return num + 1
end

return generateDiscriminator