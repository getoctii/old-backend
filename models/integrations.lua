local Model = require('lapis.db.model').Model

local Integrations = Model:extend('integrations', {
  relations = {
    { 'community', belongs_to = 'communities' },
    { 'resource', belongs_to = 'resources'}
  },
  primary_key = { 'community_id', 'resource_id' }
})

return Integrations