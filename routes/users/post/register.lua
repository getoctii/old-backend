local validate = require 'lapis.validate'
local Users = require 'models.users'
local argon2 = require 'argon2'
local uuid = require 'util.uuid'
local encoding = require 'lapis.util.encoding'
local rand = require 'openssl.rand'
local http = require 'resty.http'
local json = require 'cjson'
local generateLoginToken = require 'util.jwt'
local Codes = require 'models.codes'
local helpers = require 'lapis.application'

return function(self)
  validate.assert_valid(self.params, {
    { 'username', exists = true, min_length = 3, max_length = 16, matches_pattern = '^%a+$', 'InvalidUsername' },
    { 'password', exists = true, min_length = 8, max_length = 128, 'InvalidPassword' },
    { 'email', exists = true, min_length = 3, max_length = 128, 'InvalidEmail' },
    { 'codes', exists = true, is_uuid = true, 'WrongBetaCode' }
  })

  print('lmaosuckmycock')

  local code = helpers.assert_error(Codes:find({ id = self.params.code }), { 400, 'WrongBetaCode' })
  if code.used then helpers.yield_error({ 400, 'WrongBetaCode' }) end

  local salt = encoding.encode_base64(assert(rand.bytes(32))) -- 256 bit salt because we paranoid bois
  local hashed = assert(argon2.hash_encoded(self.params.password, salt, {
    variant = argon2.variants.argon2_id,
    parallelism = 2,
    m_cost = 2 ^ 18,
    t_cost = 8
  }))

  -- local httpc = assert(http.new())
  -- local res = assert(httpc:request_uri('https://api.nekos.dev/api/v3/images/sfw/img/neko_avatars_avatar'))
  -- local avatar_url = json.decode(res.body).data.response.url

  local user = assert(Users:create({
    username = self.params.username,
    password = hashed,
    email = self.params.email,
    id = assert(uuid()),
    avatar = "https://cdn.nekos.life/v3/sfw/img/neko_avatars_avatar/neko_103.jpg",
    discriminator = 6969
  }))

  code:update({
    used = true
  })

  return {
    status = 201,
    json = {
      authorization = generateLoginToken(user.id)
    }
  }
end