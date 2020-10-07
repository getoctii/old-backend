local helpers = require 'lapis.application'

local Channels = require 'models.channels'
local Users = require 'models.users'
local broadcast = require 'util.broadcast'
local validate = require 'lapis.validate'
local map = require 'util.map'
local contains = require 'util.contains'


return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
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

  local user = assert(Users:find({ id = self.user_id }))

  broadcast('channel:' .. channel.id, 'TYPING', {
    channel_id = channel.id,
    user_id = user.id,
    username = user.username
  })

  return {
    status = 204
  }
end