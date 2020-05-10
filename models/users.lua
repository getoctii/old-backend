local Model = require('lapis.db.model').Model

local Users = Model:extend('users', {
  relations = {
    { 'messages', has_many = 'messages' },
    { 'members', has_many = 'members' }
  }
})

return Users
