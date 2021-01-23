local helpers = require 'lapis.application'
local UsersModel = require 'models.users'
local validate = require 'lapis.validate'

local Users = {}

function Users:PATCH()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })
  local user = helpers.assert_error(UsersModel:find({ id = self.params.id }), { 404, 'UserNotFound' })
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