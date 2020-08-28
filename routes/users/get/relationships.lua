local Users = require 'models.users'
local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local preload = require 'lapis.db.model'.preload

local json = require 'cjson'

local map = require 'util.map'
local filter = require 'util.filter'
local empty = require 'util.empty'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local user = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' })
  helpers.assert_error(self.params.id == self.user_id, { 403, 'InvalidUser' })

  local incoming = user:get_incoming_relationships()
  local outgoing = user:get_outgoing_relationships()

  local incoming_requests = map(filter(incoming, function(relationship)
    return not relationship.accepted
  end), function(relationship)
    return { id = relationship.id, user = relationship.user_id }
  end)

  local outgoing_requests = map(filter(outgoing, function(relationship)
    return not relationship.accepted
  end), function(relationship)
    return { id = relationship.id, user = relationship.recipient_id }
  end)

  local relationships = map(filter(outgoing, function(relationship)
    return relationship.accepted
  end), function(relationship)
    return { id = relationship.id, user = relationship.recipient_id }
  end)

  if empty(relationships) then
    relationships = json.empty_array
  end

  if empty(incoming_requests) then
    incoming_requests = json.empty_array
  end

  if empty(outgoing_requests) then
    outgoing_requests = json.empty_array
  end

  return {
    json = {
      relationships = relationships,
      incoming = incoming_requests,
      outgoing = outgoing_requests
    }
  }
end