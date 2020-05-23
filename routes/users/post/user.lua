local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Users = require 'models.users'

local argon2 = require 'argon2'
local generateLoginToken = require 'util.jwt'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
  })

  local user = helpers.assert_error(Users:find({ id = self.params.id }), 'UserNotFound')
  if self.params.avatar then
    user.avatar = self.params.avatar
    user:update('avatar')
  end

  return {
    json = {
      avatar = user.avatar
    }
  }
end
