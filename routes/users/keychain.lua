local encode_json = require 'pgmoon.json'.encode_json
local Users = require 'models.users'
local helpers = require 'lapis.application'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local json = require 'cjson'
local db = require 'lapis.db'
local custom_types = require 'util.types'

local Keychain = {}

function Keychain:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local user = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' })

  return {
    json = user.keychain == db.null and json.null or user.keychain
  }
end

function Keychain:PUT()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    keychain = custom_types.keychain
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })
  local user = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' })

  user:update({
    keychain = db.raw(encode_json(params.keychain))
  })

  return {
    layout = false
  }
end

return Keychain