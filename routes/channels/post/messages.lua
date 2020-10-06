local helpers = require 'lapis.application'

local Channels = require 'models.channels'
local Messages = require 'models.messages'
local uuid = require 'util.uuid'
local map = require 'util.map'
local contains = require 'util.contains'

local broadcast = require 'util.broadcast'
local validate = require 'lapis.validate'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'content', exists = true, min_length = 1, max_length = 2000 , 'InvalidMessage'}
  })
  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user_id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user_id), { 403, 'MissingPermissions' })
  end

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
    author = {
      id = author.id,
      username = author.username,
      avatar = author.avatar,
      discriminator = author.discriminator
    }
  }

  if channel.community_id then
    local community = channel:get_community()
    message_event.community_name = community.name
    message_event.channel_name = channel.name
  end

  broadcast('channel:' .. channel.id, 'NEW_MESSAGE', message_event)

  return {
    json = message
  }
end