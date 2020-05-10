local jwt = require 'resty.jwt'

local function generateLoginToken(id)
  local keyfile = io.open('jwtrs256.key', 'r')
  local key = keyfile:read('a')
  local table = {
    header = {
      typ = 'JWT',
      alg = 'RS256'
    },
    payload = {
      user = {
        id = id
      }
    }
  }
  return jwt:sign(key, table)
end

return generateLoginToken