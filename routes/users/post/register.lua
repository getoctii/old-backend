local validate = require 'lapis.validate'
local Users = require 'models.users'
local argon2 = require 'argon2'
local uuid = require 'util.uuid'
local encoding = require 'lapis.util.encoding'
local rand = require 'openssl.rand'
local generateLoginToken = require 'util.jwt'
local Codes = require 'models.codes'
local helpers = require 'lapis.application'
local generateDiscriminator = require 'util.generatediscriminator'

return function(self)
  validate.assert_valid(self.params, {
    { 'username', exists = true, min_length = 3, max_length = 16, matches_pattern = '^%a+$', 'InvalidUsername' },
    { 'password', exists = true, min_length = 8, max_length = 128, 'InvalidPassword' },
    { 'email', exists = true, min_length = 3, max_length = 128, matches_pattern = '^[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?$', 'InvalidEmail' },
    { 'betaCode', exists = true, is_uuid = true, 'WrongBetaCode' }
  })

  local code = helpers.assert_error(Codes:find({ id = self.params.betaCode }), { 400, 'WrongBetaCode' })
  if code.used then helpers.yield_error({ 400, 'WrongBetaCode' }) end

  local salt = encoding.encode_base64(assert(rand.bytes(32))) -- 256 bit salt because we paranoid bois
  local hashed = assert(argon2.hash_encoded(self.params.password, salt, {
    variant = argon2.variants.argon2_id,
    parallelism = 2,
    m_cost = 2 ^ 18,
    t_cost = 8
  }))

  local user = assert(Users:create({
    username = self.params.username,
    password = hashed,
    email = self.params.email,
    id = assert(uuid()),
    avatar = "https://cdn.nekos.life/avatar/avatar_54.png",
    discriminator = generateDiscriminator(self.params.username)
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