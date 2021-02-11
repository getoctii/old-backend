local model = require('lapis.db.model')
local Model, enum = model.Model, model.enum

local Relationships = Model:extend('relationships', {
  relations = {
    { 'user', belongs_to = 'users' },
    { 'recipient', belongs_to = 'users' }
  },
  primary_key = { 'user_id', 'recipient_id' }
})

Relationships.types = enum {
  OUTGOING_FRIEND_REQUEST = 1,
  INCOMING_FRIEND_REQUEST = 2,
  FRIEND = 3,
  BLOCKED = 4
}

return Relationships
