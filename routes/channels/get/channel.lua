local helpers = require 'lapis.application'
local validate = require 'lapis.validate'

local map = require 'util.map'
local contains = require 'util.contains'

local Channels = require 'models.channels'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' }}
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

  return {
    json = {
      name = channel.name,
      community_id = channel.community_id
    }
  }
end