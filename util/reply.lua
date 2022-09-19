local config = require 'lapis.config'.get()
local uuid = require 'util.uuid'
local jwt = require 'resty.jwt'

local function generateReplyToken(id)
  local time = os.time()

  local table = {
    header = {
      typ = 'JWT',
      alg = 'RS256'
    },
    payload = {
      type = 'reply',
      iss = 'chat.innatical.com',
      aud = 'chat.innatical.com',
      sub = id,
      iat = time,
      nbf = time,
      exp = time + 600, -- 10 minutes in seconds
      jti = uuid()
    }
  }
  return jwt:sign(config.jwt.private, table)

end

return generateReplyToken