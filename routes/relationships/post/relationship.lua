local helpers = require 'lapis.helpers'
local validate = require 'lapis.validate'
local Relationships = require 'models.relationships'
local Users = require 'models.users'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'

return function(self)
  validate.assert_valid(self.params, {
    { 'recipient_id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.params.recipient_id ~= self.user_id, { 400, 'InvalidRecipient'})
  local recipient = helpers.assert_error(Users:find(self.params.recipient_id), { 404, 'RecipientNotFound' })
  helpers.assert_error(not Relationships:find({ user_id = self.user_id, recipient_id = self.recipient.id }), { 400, 'RelationshipAlreadyExists' })
  local incoming = Relationships:find({ user_id = self.params.recipient_id, recipient_id = self.user_id })

  local relationship = assert(Relationships:create({
    id = uuid(),
    user_id = self.user_id,
    recipient_id = recipient.id,
    accepted = not not incoming
  }))

  broadcast('user:' .. relationship.user_id, 'NEW_RELATIONSHIP', {
    id = relationship.id,
    user = relationship.recipient_id,
    accepted = not not incoming
  })

  broadcast('user:' .. relationship.recipient_id, 'NEW_RELATIONSHIP', {
    id = relationship.id,
    user = relationship.user_id,
    accepted = not not incoming
  })

  if incoming then
    incoming:update({
      accepted = true
    })

    broadcast('user:' .. relationship.user_id, 'UPDATE_RELATIONSHIP', {
      id = relationship.id,
      user = relationship.recipient_id,
      accepted = true
    })

    broadcast('user:' .. relationship.recipient_id, 'UPDATE_RELATIONSHIP', {
      id = relationship.id,
      user = relationship.user_id,
      accepted = true
    })
  end

  return {
    status = 204,
    layout = false
  }
end