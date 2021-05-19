local helpers = require 'lapis.application'
local Users = require 'models.users'
local Channels = require 'models.channels'
local uuid = require 'util.uuid'
local Participants = require 'models.participants'
local Conversations = require 'models.conversations'
local db = require 'lapis.db'
local resubscribe = require 'util.resubscribe'
local broadcast = require 'util.broadcast'
local are_friends = require 'util.are_friends'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Create = {}

function Create:POST() -- TODO: Damn, we make a lot of queries here. Let's consider batching them.
  local params = validate(self.params, types.shape {
    recipient = custom_types.uuid
  })

  helpers.assert_error(params.recipient ~= self.user.id, { 422, 'InvalidRecipient' }) -- TODO: add as validation

  local recipient = helpers.assert_error(Users:find({ id = params.recipient }), { 404, 'RecipientNotFound' })
  -- helpers.assert_error(not db.select('A.conversation_id, A.user_id, B.user_id FROM participants A, participants B WHERE A.conversation_id = B.conversation_id AND (A.user_id = ? OR A.user_id = ?) AND (B.user_id = ? OR B.user_id = ?);', self.user.id, recipient.id, self.user.id, recipient.id), { 422, 'AlreadyExists' })

  helpers.assert_error(are_friends(self.user.id, recipient.id), { 422, 'NotFriends' })

  local channel = Channels:create({
    id = uuid(),
    name = 'nekos-are-cute',
    community_id = db.NULL
  })

  local voice_channel = Channels:create({
    id = uuid(),
    name = 'nekos-are-cute',
    community_id = db.NULL,
    type =  Channels.types.VOICE
  })

  local conversation = Conversations:create({
    id = uuid(),
    channel_id = channel.id,
    voice_channel_id = voice_channel.id
  })

  local from = assert(Participants:create({
    id = assert(uuid()),
    user_id = self.user.id,
    conversation_id = conversation.id
  }))

  local to = assert(Participants:create({
    id = assert(uuid()),
    user_id = recipient.id,
    conversation_id = conversation.id
  }))

  resubscribe('user:' .. self.user.id)
  resubscribe('user:' .. recipient.id)

  -- TODO: Batch these broadcast messages
  broadcast('user:' .. self.user.id, 'NEW_PARTICIPANT', {
    id = from.id,
    conversation = {
      id = conversation.id,
      channel_id = channel.id,
      voice_channel_id = conversation.voice_channel_id,
      participants = {self.user.id, recipient.id}
    }
  })

  broadcast('user:' .. recipient.id, 'NEW_PARTICIPANT', {
    id = to.id,
    conversation = {
      id = conversation.id,
      channel_id = channel.id,
      voice_channel_id = conversation.voice_channel_id,
      participants = {self.user.id, recipient.id}
    }
  })

  return {
    json = {
      id = conversation.id,
      channel_id = conversation.id
    }
  }
end

return Create