local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local map = require 'util.map'
local contains = require 'util.contains'
local broadcast = require 'util.broadcast'

local Message = require 'models.messages'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local message = helpers.assert_error(Message:find({ id = self.params.id }), 'MessageNotFound')
  local channel = message:get_channel()

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user_id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user_id), { 403, 'MissingPermissions' })
  end

  helpers.assert_error(message:get_author().id == self.user_id, { 403, 'MissingPermissions' })

  assert(message:delete())

  broadcast('channel:' .. channel.id, 'DELETED_MESSAGE', {
    id = message.id,
    channel_id = channel.id
  })

  return {
    layout = false
  }
end
