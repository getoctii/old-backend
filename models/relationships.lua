local Model = require('lapis.db.model').Model

local Relationships = Model:extend('relationships', {
  relations = {
    { 'user', belongs_to = 'users' },
    { 'recipient', belongs_to = 'users' }
  }
})

return Relationships
