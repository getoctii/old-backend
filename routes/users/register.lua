local encode_json = require 'pgmoon.json'.encode_json
local Users = require 'models.users'
local argon2 = require 'argon2'
local uuid = require 'util.uuid'
local encoding = require 'lapis.util.encoding'
local rand = require 'openssl.rand'
local generateLoginToken = require 'util.jwt'
local Codes = require 'models.codes'
local helpers = require 'lapis.application'
local generateDiscriminator = require 'util.generatediscriminator'
local config = require 'lapis.config'.get()
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local db = require 'lapis.db'

local Register = {}

function Register:POST()
  local params = validate(self.params, types.shape {
    username = custom_types.username,
    password = custom_types.password,
    email = custom_types.email,
    keychain = custom_types.keychain
  })

  local salt = encoding.encode_base64(assert(rand.bytes(32))) -- 256 bit salt because we paranoid bois
  local hashed = assert(argon2.hash_encoded(params.password, salt, {
    variant = argon2.variants.argon2_id,
    parallelism = 2,
    m_cost = 2 ^ 18,
    t_cost = 8
  }))

  local user = Users:create({
    username = params.username,
    password = hashed,
    email = params.email,
    id = assert(uuid()),
    avatar = config.default_profile_pictures[math.random(#config.default_profile_pictures)],
    discriminator = generateDiscriminator(params.username),
    keychain = db.raw(encode_json(params.keychain))
  })

  return {
    status = 201,
    json = {
      authorization = generateLoginToken(user.id)
    }
  }
end

return Register