local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Conversations = require 'models.conversations'
local contains = require 'array'.includes
local map = require 'array'.map
local Users = require 'models.users'
local Channels = require 'models.channels'
local uuid = require 'util.uuid'
local Participants = require 'models.participants'
local resubscribe = require 'util.resubscribe'
local broadcast = require 'util.broadcast'
local db = require 'lapis.db'

local Conversation = {}

function Conversation:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local conversation = helpers.assert_error(Conversations:find({ id = self.params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user_id), { 403, 'MissingPermissions' })

  return {
    json = {
      id = conversation.id,
      channel_id = conversation.get_channel().id
    }
  }
end

function Conversation:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local conversation = helpers.assert_error(Conversations:find({ id = self.params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user_id), { 403, 'MissingPermissions' })

  local participant = assert(Participants:find({ conversation_id = conversation.id, user_id = self.user_id}))
  participant:delete()

  -- TODO: Notify other partiticpants.
  broadcast('user:' .. self.user_id, 'DELETED_PARTICIPANT', {
    id = participant.id
  })

  return {
    layout = false
  }
end

return Conversation