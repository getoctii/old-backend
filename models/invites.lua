local Model = require('lapis.db.model').Model

local Invites = Model:extend('invites', {
  timestamp = true,
  relations = {
    { 'community', belongs_to = 'communities' },
    { 'author', belongs_to = 'user'}
  }
})

return Invites