local Users = require 'models.users'
local helpers = require 'lapis.application'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local otp = require 'otp'
local db = require 'lapis.db'

local TOTP = {}

function TOTP:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local user = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' })
  helpers.assert_error(not user.totp_key, { 400, 'AlreadyInitalized' })

  local totp = otp.new_totp()
  local key = totp:get_key()

  user:update({
    totp_key = key
  })

  return {
    json = {
      url = totp:get_url("Octii", user.username),
      key = key
    }
  }
end

function TOTP:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    code = types.string / tonumber * types.integer / tostring
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local user = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' })
  helpers.assert_error(user.totp_key, { 400, 'NotInitalized' })

  local totp = otp.new_totp_from_key(user.totp_key)
  helpers.assert_error(totp:verify(params.code), { 403, 'Unauthorized' })

  user:update({
    totp_key = db.NULL
  })

  return {
    layout = false
  }
end

return TOTP