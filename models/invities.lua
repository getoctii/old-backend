local Model = require('lapis.db.model').Model

local Invities = Model:extend('invities', {
  relations = {
    { 'community', belongs_to = 'communities' },
    { 'member', belongs_to = 'members' }
  }
})

return Invities
