local helpers = require 'lapis.application'
local Users = require 'models.users'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local db = require 'lapis.db'
local otp = require 'otp'

local argon2 = require 'argon2'
local generateLoginToken = require 'util.jwt'

local Login = {}

function Login:GET()
  local params = validate(self.params, types.shape {
    email = custom_types.email
  })

  local user = helpers.assert_error(Users:find({ email = params.email }), { 404, 'UserNotFound' })
  helpers.assert_error(not user.disabled, { 403, 'DisabledUser' })

  local keychain = user.keychain == db.null and {} or user.keychain

  return {
    json = {
      totp = not not user.totp_key,
      tokenSalt = keychain.tokenSalt
    }
  }
end

function Login:POST()
  local params = validate(self.params, types.shape {
    email = custom_types.email,
    password = custom_types.password,
    code = (types.string / tonumber * types.integer / tostring):is_optional()
  })

  local user = helpers.assert_error(Users:find({ email = params.email }), { 404, 'UserNotFound' })
  helpers.assert_error(not user.disabled, { 403, 'DisabledUser' })
  helpers.assert_error(argon2.verify(user.password, params.password), { 401, 'WrongPassword' })

  if user.totp_key then
    helpers.assert_error(params.code, { 400, 'InvalidParameters' })
    local totp = otp.new_totp_from_key(user.totp_key)
    helpers.assert_error(totp:verify(params.code), { 403, 'WrongCode' })
  end

  return {
    json = {
      authorization = generateLoginToken(user.id)
    }
  }
end

return Login