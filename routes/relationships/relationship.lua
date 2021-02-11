local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local RelationshipsModel = require 'models.relationships'
local broadcast = require 'util.broadcast'
local db = require 'lapis.db'

local Relationship = {}

function Relationship:POST()
  validate.assert_valid(self.params, {
    { 'recipient_id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.params.recipient_id ~= self.user.id, { 400, 'InvalidRecipient' })

  RelationshipsModel:create({
    user_id = self.user.id,
    recipient_id = self.params.recipient_id,
    type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST
  })

  if RelationshipsModel:find({
    user_id = self.params.recipient_id,
    recipient_id = self.user.id,
    type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST
  }) then
    broadcast('user:' .. self.user.id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = self.params.recipient_id,
      type = RelationshipsModel.types.FRIEND
    })
    broadcast('user:' ..self.params.recipient_id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = self.params.recipient_id,
      type = RelationshipsModel.types.FRIEND
    })
  else
    broadcast('user:' .. self.user.id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = self.params.recipient_id,
      type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST
    })
    broadcast('user:' ..self.params.recipient_id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = self.params.recipient_id,
      type = RelationshipsModel.types.INCOMING_FRIEND_REQUEST
    })
  end

  return {
    layout = false,
    status = 204
  }
end

function Relationship:DELETE()
  validate.assert_valid(self.params, {
    { 'recipient_id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.params.recipient_id ~= self.user.id, { 400, 'InvalidRecipient' })

  db.delete('relationships', { user_id = self.user.id, recipient_id = self.params.recipient_id })
  db.delete('relationships', { user_id = self.params.recipient_id, recipient_id = self.user.id })

  broadcast('user:' .. self.user.id, 'DELETED_RELATIONSHIP', {
    user_id = self.user.id,
    recipient_id = self.params.recipient_id
  })
  broadcast('user:' .. self.params.recipient_id, 'DELETED_RELATIONSHIP', {
    user_id = self.user.id,
    recipient_id = self.params.recipient_id
  })

  return {
    layout = false,
    status = 204
  }
end

return Relationship