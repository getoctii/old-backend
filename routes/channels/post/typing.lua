local helpers = require 'lapis.application'

local Channels = require 'models.channels'
local Users = require 'models.users'
local broadcast = require 'util.broadcast'

return function(self)
  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })
  local user = assert(Users:find({ id = self.user_id }))

  broadcast('channel:' .. channel.id, 'TYPING', {
    id = user.id,
    username = user.username,
    avatar = user.avatar,
    discriminator = user.discriminator
  })

  return {
    status = 204
  }
end