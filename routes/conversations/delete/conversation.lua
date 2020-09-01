local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local map = require 'util.map'
local contains = require 'util.contains'

local Conversations = require 'models.conversations'
local Participants = require 'models.participants'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' } }
  })

  local conversation = helpers.assert_error(Conversations:find({ id = self.params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user_id), { 403, 'MissingPermissions' })

  local participant = assert(Participants.find({ conversation_id = conversation.id, user_id = self.user_id}))
  participant:delete()

  return {
    layout = false
  }
end