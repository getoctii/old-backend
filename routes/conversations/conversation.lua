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
local preload = require 'lapis.db.model'.preload
local MessagesModel = require 'models.messages'
local joinMessages = require 'util.messages'.joinMessages
local leaveMessages = require 'util.messages'.leaveMessages

local Conversation = {}

function Conversation:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local conversation = helpers.assert_error(Conversations:find({ id = self.params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user.id), { 403, 'MissingPermissions' })

  return {
    json = {
      id = conversation.id,
      channel_id = conversation.get_channel().id
    }
  }
end

function Conversation:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'recipient', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local conversation = helpers.assert_error(Conversations:find({ id = self.params.id }), { 404, 'ConversationNotFound' })
  helpers.assert_error(contains(map(conversation:get_participants(), function(participant)
    return participant.user_id
  end), self.user.id), { 403, 'MissingPermissions' })

  helpers.assert_error(self.params.recipient ~= self.user.id, { 422, 'InvalidRecipient' }) -- TODO: add as validation

  local recipient = helpers.assert_error(Users:find({ id = self.params.recipient }), { 404, 'RecipientNotFound' })

  local user_ids = map(conversation:get_participants(), function(row) return row.user_id end)

  -- TODO: Maybe use a multiple column key to ensure uniqueness?
  helpers.assert_error(not contains(user_ids, self.params.recipient), { 422, 'InvalidRecipient' })

  local from = assert(Participants:create({
    id = assert(uuid()),
    user_id = recipient.id, -- TODO: check that acc exists
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
    content = '<@' .. self.params.recipient .. '>' .. joinMessages[math.random(#joinMessages)],
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
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local conversation = helpers.assert_error(Conversations:find({ id = self.params.id }), { 404, 'ConversationNotFound' })
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