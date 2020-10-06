local Model = require('lapis.db.model').Model

local Members = Model:extend('members', {
  timestamp = true,
  relations = {
    { 'user', belongs_to = 'users' },
    { 'community', belongs_to = 'communities' }
  }
})

return Members
