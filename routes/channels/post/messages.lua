local helpers = require 'lapis.application'

local Channels = require 'models.channels'
local Messages = require 'models.messages'
local uuid = require 'util.uuid'

local broadcast = require 'util.broadcast'

return function(self)
  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), 'ChannelNotFound')

  local row = Messages:create({
    id = uuid(),
    author_id = self.user_id,
    content = self.params.content,
    channel_id = channel.id
  })

  local author = row:get_author()

  local message = {
    id = row.id,
    created_at = row.created_at,
    updated_at = row.updated_at,
    content = row.content
  }

  local message_event = {
    id = row.id,
    created_at = row.created_at,
    updated_at = row.updated_at,
    content = row.content,
    channel_id = row.channel_id,
    author_id = row.author_id,
    community_id = channel.community_id,
    author = {
      id = author.id,
      username = author.username,
      avatar = author.avatar,
      discriminator = author.discriminator
    }
  }

  broadcast('channel:' .. channel.id, 'NEW_MESSAGE', message_event)

  return {
    json = message
  }
end