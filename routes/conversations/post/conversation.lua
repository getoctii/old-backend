local Communities = require 'models.communities'
local Users = require 'models.users'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Conversations = require 'models.conversations'
local Channels = require 'models.channels'
local Participants = require 'models.participants'
local db = require 'lapis.db'

local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local inspect = require 'inspect'

return function(self) -- Damn, we make a lot of queries here. Let's consider batching them.
  validate.assert_valid(self.params, {
    { 'recipient', exists = true, is_uuid = true, { 400, 'InvalidUUID' } }
  })

  helpers.assert_error(self.params.recipient ~= self.user_id, { 422, 'InvalidRecipient' }) -- TODO: add as validation

  local recipient = helpers.assert_error(Users:find({ id = self.params.recipient }), { 404, 'RecipientNotFound' })

  local channel = Channels:create({
    id = uuid(),
    name = 'nekos-are-cute',
    community_id = db.NULL
  })

  local conversation = Conversations:create({
    id = uuid(),
    channel_id = channel.id
  })

  local from = assert(Participants:create({
    id = assert(uuid()),
    user_id = self.user_id, -- TODO: check that acc exists
    conversation_id = conversation.id
  }))

  local to = assert(Participants:create({
    id = assert(uuid()),
    user_id = recipient.id, -- TODO: check that acc exists
    conversation_id = conversation.id
  }))
  -- TODO: Batch these broadcast messages
  broadcast('user:' .. self.user_id, 'NEW_PARTICIPANT', {
    id = from.id,
    conversation= {
      id = conversation.id,
      channel_id = channel.id,
      participants = {self.user_id, recipient.id}
    }
  })

  resubscribe('user:' .. self.user_id)

  broadcast('user:' .. recipient.id, 'NEW_PARTICIPANT', {
    id = to.id,
    conversation= {
      id = conversation.id,
      channel_id = channel.id,
      participants = {self.user_id, recipient.id}
    }
  })

  resubscribe('user:' .. recipient.id)

  return {
    json = {
      id = conversation.id,
      channel_id = conversation.id
    }
  }
end