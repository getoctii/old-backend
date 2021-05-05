local helpers = require 'lapis.application'
local Users = require 'models.users'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local db = require 'lapis.db'

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
      tokenSalt = keychain.tokenSalt
    }
  }
end

function Login:POST()
  local params = validate(self.params, types.shape {
    email = custom_types.email,
    password = custom_types.password
  })

  local user = helpers.assert_error(Users:find({ email = params.email }), { 404, 'UserNotFound' })
  helpers.assert_error(not user.disabled, { 403, 'DisabledUser' })
  helpers.assert_error(argon2.verify(user.password, params.password), { 401, 'WrongPassword' })

  return {
    json = {
      authorization = generateLoginToken(user.id)
    }
  }
end

return Login