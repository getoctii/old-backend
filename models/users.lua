local model = require('lapis.db.model')
local Model, enum = model.Model, model.enum

local Users = Model:extend('users', {
  relations = {
    { 'messages', has_many = 'messages' },
    { 'members', has_many = 'members' },
    { 'participants', has_many = 'participants' },
    { 'incoming_relationships', key = 'recipient_id', has_many = 'relationships' },
    { 'outgoing_relationships', has_many = 'relationships' }
  }
})

Users.states = enum {
  offline = 1,
  idle = 2,
  dnd = 3,
  online = 4
}

return Users
