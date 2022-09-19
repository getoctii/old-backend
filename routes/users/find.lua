local helpers = require 'lapis.application'
local Users = require 'models.users'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Find = {}

function Find:GET()
  local params = validate(self.params, types.shape {
    username = custom_types.username,
    discriminator = custom_types.discriminator + (types.string / tonumber * custom_types.discriminator)
  })

  local user = helpers.assert_error(Users:find({
    username = params.username,
    discriminator = params.discriminator
  }), { 404, 'UserNotFound' })

  local info = {
    id = user.id,
    username = user.username,
    avatar = user.avatar,
    discriminator = user.discriminator
  }

  if user.id == self.user.id then
    info.email = user.email
  end

  return {
    json = info
  }
end

return Find