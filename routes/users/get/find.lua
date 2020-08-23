local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Users = require 'models.users'

return function(self)
  validate.assert_valid(self.params, {
    { 'username', exists = true, min_length = 3, max_length = 16, matches_pattern = '^%a+$', { 400, 'InvalidUsername' }},
    { 'discriminator', exists = true, is_integer = true, { 400, 'InvalidDiscriminator' }}
  })

  local user = helpers.assert_error(Users:find({ username = self.params.username, discriminator = self.params.discriminator }), { 404, 'UserNotFound' })

  local info = {
    id = user.id,
    username = user.username,
    avatar = user.avatar,
    discriminator = user.discriminator
  }

  if user.id == self.user_id then
    info.email = user.email
  end

  return {
    json = info
  }
end