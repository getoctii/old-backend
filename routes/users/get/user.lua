local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Users = require 'models.users'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })

  local user = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' })

  local info = {
    id = user.id,
    username = user.username,
    avatar = user.avatar,
    discriminator = user.discriminator,
    status = user.status,
    state = Users.states:to_name(user.state)
  }

  if user.id == self.user_id then
    info.email = user.email
  end

  return {
    json = info
  }
end
