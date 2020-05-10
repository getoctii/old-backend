local Model = require('lapis.db.model').Model

local Members = Model:extend('members', {
  { 'user', belongs_to = 'users' },
  { 'member', belongs_to = 'communities' }
})

return Members
