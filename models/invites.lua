local Model = require('lapis.db.model').Model

local Invites = Model:extend('invites', {
  relations = {
    { 'community', belongs_to = 'comunity' }
  }
})

return Invites