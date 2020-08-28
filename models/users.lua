local Model = require('lapis.db.model').Model

local Users = Model:extend('users', {
  relations = {
    { 'messages', has_many = 'messages' },
    { 'members', has_many = 'members' },
    { 'participants', has_many = 'participants' },
    { 'incoming_relationships', key = 'recipient_id', has_many = 'relationships' },
    { 'outgoing_relationships', has_many = 'relationships' }
  }
})

return Users
