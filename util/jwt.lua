local config = require 'lapis.config'.get()
local uuid = require 'util.uuid'
local jwt = require 'resty.jwt'

local function generateLoginToken(id)
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
  return jwt:sign(config.jwt.private, table)
end

return generateLoginToken
