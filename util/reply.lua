local config = require 'lapis.config'.get()
local uuid = require 'util.uuid'
local jwt = require 'resty.jwt'

local function generateReplyToken(id)
  local keyfile = assert(io.open(config.jwt.private, 'r'))
  local key = assert(keyfile:read('a'))
  keyfile:close()
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
  return jwt:sign(key, table)

end

return generateReplyToken