local helpers = require 'lapis.application'
local RelationshipsModel = require 'models.relationships'
local array = require 'array'
local json = require 'cjson'
local Set = require 'pl.Set'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Relationships = {}

local function row_map(type)
  return function (row)
    return type == RelationshipsModel.types.INCOMING_FRIEND_REQUEST and row.user_id or row.recipient_id
  end
end

function Relationships:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local relationships = RelationshipsModel:select('WHERE user_id = ? OR recipient_id = ?', self.user.id, self.user.id)

  local incoming_set = Set(array.map(array.filter(relationships, function(row)
    return row.recipient_id == self.user.id
  end), row_map(RelationshipsModel.types.INCOMING_FRIEND_REQUEST)))
  local outgoing_set = Set(array.map(array.filter(relationships, function(row)
    return row.user_id == self.user.id
  end), row_map(RelationshipsModel.types.OUTGOING_FRIEND_REQUEST)))
  local friends = incoming_set * outgoing_set

  incoming_set = incoming_set - friends
  outgoing_set = outgoing_set - friends

  local formatted = array.concat(
    array.map(Set.values(incoming_set), function(id)
      return {
        user_id = id,
        recipient_id = self.user.id,
        type = RelationshipsModel.types.INCOMING_FRIEND_REQUEST
      }
    end),
    array.map(Set.values(outgoing_set), function(id)
      return {
        user_id = self.user.id,
        recipient_id = id,
        type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST
      }
    end),
    array.map(Set.values(friends), function(id)
      return {
        user_id = self.user.id,
        recipient_id = id,
        type = RelationshipsModel.types.FRIEND
      }
    end)
  )

  return {
    layout = false,
    status = 200,
    json = array.is_empty(formatted) and json.empty_array or formatted
  }
end

return Relationships