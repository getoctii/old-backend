local helpers = require 'lapis.application'
local Conversations = require 'models.conversations'
local contains = require 'array'.includes
local map = require 'array'.map
local Users = require 'models.users'
local uuid = require 'util.uuid'
local Participants = require 'models.participants'
local resubscribe = require 'util.resubscribe'
local broadcast = require 'util.broadcast'
local db = require 'lapis.db'
local MessagesModel = require 'models.messages'
local joinMessages = require 'util.messages'.joinMessages
local leaveMessages = require 'util.messages'.leaveMessages
local are_friends = require 'util.are_friends'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Conversation = {}

function Conversation:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local conversation = helpers.assert_error(Conversations:find({ id = params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user.id), { 403, 'MissingPermissions' })

  return {
    json = {
      id = conversation.id,
      channel_id = conversation.channel_id,
      voice_channel_id = conversation.voice_channel_id
    }
  }
end

function Conversation:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    recipient = custom_types.uuid
  })

  local conversation = helpers.assert_error(Conversations:find({ id = params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user.id), { 403, 'MissingPermissions' })

  helpers.assert_error(params.recipient ~= self.user.id, { 422, 'InvalidRecipient' }) -- TODO: add as validation

  local recipient = helpers.assert_error(Users:find({ id = params.recipient }), { 404, 'RecipientNotFound' })
  helpers.assert_error(are_friends(self.user.id, recipient.id), { 422, 'NotFriends' })

  local user_ids = map(conversation:get_participants(), function(row) return row.user_id end)

  -- TODO: Maybe use a multiple column key to ensure uniqueness?
  helpers.assert_error(not contains(user_ids, params.recipient), { 422, 'InvalidRecipient' })

  local from = assert(Participants:create({
    id = assert(uuid()),
    user_id = recipient.id,
    conversation_id = conversation.id
  }))

  conversation:refresh()
  user_ids = map(conversation:get_participants(), function(row) return row.user_id end)

  broadcast('conversation:' .. conversation.id, 'UPDATED_CONVERSATION', {
    conversation_id = conversation.id,
    participants = user_ids
  })

  local row = MessagesModel:create({
    id = uuid(),
    author_id = '30eeda0f-8969-4811-a118-7cefa01098a3',
    content = '<@' .. params.recipient .. '>' .. joinMessages[math.random(#joinMessages)],
    channel_id = conversation.channel_id,
    type = 3
  })

  local author = row:get_author()

  broadcast('channel:' .. conversation.channel_id, 'NEW_MESSAGE', {
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
    },
    type = row.type,
    community_id = conversation.channel_id,
  })

  resubscribe('user:' .. recipient.id)

  local channel = conversation:get_channel()
  local pager = channel:get_messages_paginated({
    per_page = 1,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  broadcast('user:' .. recipient.id, 'NEW_PARTICIPANT', {
    id = from.id,
    conversation = {
      id = conversation.id,
      channel_id = conversation.channel_id,
      voice_channel_id = conversation.voice_channel_id,
      last_message_id = (pager:get_page()[1] or {}).id,
      participants = user_ids
    }
  })

  return {
    status = 201,
    layout = false
  }
end

function Conversation:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local conversation = helpers.assert_error(Conversations:find({ id = params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user.id), { 403, 'MissingPermissions' })

  local participant = assert(Participants:find({ conversation_id = conversation.id, user_id = self.user.id}))
  assert(db.delete('participants', {
    id = participant.id
  }))

  broadcast('conversation:' .. conversation.id, 'DELETED_PARTICIPANT', {
    id = participant.id,
    user_id = self.user.id,
    conversation_id = participant:get_conversation().id
  })

  resubscribe('conversation:' .. conversation.id)

  local row = MessagesModel:create({
    id = uuid(),
    author_id = '30eeda0f-8969-4811-a118-7cefa01098a3',
    content = '<@' .. self.user.id .. '>' .. leaveMessages[math.random(#leaveMessages)],
    channel_id = conversation.channel_id,
    type = 4
  })

  local author = row:get_author()

  broadcast('channel:' .. conversation.channel_id, 'NEW_MESSAGE', {
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
    },
    type = row.type,
    community_id = conversation.channel_id,
  })

  return {
    layout = false
  }
end

return Conversation