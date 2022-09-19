local helpers = require 'lapis.application'
local UsersModel = require 'models.users'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Users = {}

function Users:PATCH()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local user = helpers.assert_error(UsersModel:find({ id = params.id }), { 404, 'UserNotFound' })
  helpers.assert_error(user.discriminator ~= 0, { 403, 'NotAllowed' })

  user:update({
    disabled = not user.disabled
  })

  return {
    status = 204,
    layout = false
  }
end

return Users