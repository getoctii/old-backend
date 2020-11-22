local validate = require 'lapis.validate'
local map = require 'util.map'
local contains = require 'util.contains'

local helpers = require 'lapis.application'

local Message = require 'models.messages'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' } }
  })

  local message = helpers.assert_error(Message:find({ id = self.params.id }), { 404, 'MessageNotFound' })
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

  return {
    json = {
      id = message.id,
      created_at = message.created_at,
      updated_at = message.updated_at,
      content = message.content,
      channel_id = message.channel_id,
      author_id = message.author_id
    }
  }
end