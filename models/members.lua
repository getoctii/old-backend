local Model = require('lapis.db.model').Model

local Members = Model:extend('members', {
  relations = {
    { 'user', belongs_to = 'users' },
    { 'community', belongs_to = 'communities' }
  }
})

return Members
