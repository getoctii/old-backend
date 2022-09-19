local helpers = require 'lapis.application'
local RelationshipsModel = require 'models.relationships'
local broadcast = require 'util.broadcast'
local db = require 'lapis.db'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local UsersModel = require 'models.users'

local Relationship = {}

function Relationship:POST()
  local params = validate(self.params, types.shape {
    recipient_id = custom_types.uuid
  })

  helpers.assert_error(params.recipient_id ~= self.user.id, { 400, 'InvalidRecipient' })
  helpers.assert_error(UsersModel:find({ id = params.recipient_id }), { 404, 'RecipientNotFound' })
  helpers.assert_error(not RelationshipsModel:find({
    user_id = self.user.id,
    recipient_id = params.recipient_id
  }), { 400, 'AlreadyExists' })
  RelationshipsModel:create({
    user_id = self.user.id,
    recipient_id = params.recipient_id,
    type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST
  })

  if RelationshipsModel:find({
    user_id = params.recipient_id,
    recipient_id = self.user.id,
    type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST
  }) then
    broadcast('user:' .. self.user.id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = params.recipient_id,
      type = RelationshipsModel.types.FRIEND
    })
    broadcast('user:' ..params.recipient_id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = params.recipient_id,
      type = RelationshipsModel.types.FRIEND
    })
  else
    broadcast('user:' .. self.user.id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = params.recipient_id,
      type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST
    })
    broadcast('user:' ..params.recipient_id, 'NEW_RELATIONSHIP', {
      user_id = self.user.id,
      recipient_id = params.recipient_id,
      type = RelationshipsModel.types.INCOMING_FRIEND_REQUEST
    })
  end

  return {
    layout = false,
    status = 204
  }
end

function Relationship:DELETE()
  local params = validate(self.params, types.shape {
    recipient_id = custom_types.uuid
  })

  helpers.assert_error(params.recipient_id ~= self.user.id, { 400, 'InvalidRecipient' })
  helpers.assert_error(UsersModel:find({ id = params.recipient_id }), { 404, 'RecipientNotFound' })

  db.delete('relationships', { user_id = self.user.id, recipient_id = params.recipient_id })
  db.delete('relationships', { user_id = params.recipient_id, recipient_id = self.user.id })

  broadcast('user:' .. self.user.id, 'DELETED_RELATIONSHIP', {
    user_id = self.user.id,
    recipient_id = params.recipient_id
  })
  broadcast('user:' .. params.recipient_id, 'DELETED_RELATIONSHIP', {
    user_id = self.user.id,
    recipient_id = params.recipient_id
  })

  return {
    layout = false,
    status = 204
  }
end

return Relationship