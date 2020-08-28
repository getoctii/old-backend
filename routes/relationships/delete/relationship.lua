local helpers = require 'lapis.helpers'
local validate = require 'lapis.validate'
local Relationships = require 'models.relationships'
local broadcast = require 'util.broadcast'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local relationship = helpers.assert_error(Relationships:find(self.params.id), { 404, 'RelationshipNotFound' })
  helpers.assert_error(relationship.user_id == self.id or relationship.recipient_id == self.id, { 403, 'NotAuthorized' })

  if relationship.accepted then
    local other = assert(Relationships:find({ user_id = relationship.recipient_id, recipient_id = relationship.recipient_id }))

    other:delete()

    broadcast('user:' .. other.user_id, 'DELETE_RELATIONSHIP', {
      id = relationship.id
    })

    broadcast('user:' .. other.recipient_id, 'DELETE_RELATIONSHIP', {
      id = relationship.id
    })
  end

  relationship:delete()

  broadcast('user:' .. relationship.user_id, 'DELETE_RELATIONSHIP', {
    id = relationship.id
  })

  broadcast('user:' .. relationship.recipient_id, 'DELETE_RELATIONSHIP', {
    id = relationship.id
  })

  return {
    status = 204,
    layout = false
  }
end