local uuid = require 'util.uuid'
local jwt = require 'resty.jwt'

local function generateLoginToken(id)
  local keyfile = io.open('jwtrs256.key', 'r')
  local key = keyfile:read('a')
  keyfile:close()
  local time = os.time()

  local table = {
    header = {
      typ = 'JWT',
      alg = 'RS256'
    },
    payload = {
      iss = 'chat.innatical.com',
      aud = 'chat.innatical.com',
      sub = id,
      iat = time,
      nbf = time,
      exp = time + 604800, -- 1 week in seconds
      jti = uuid()
    }
  }
  return jwt:sign(key, table)
end

return generateLoginToken