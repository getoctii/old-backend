local Model = require('lapis.db.model').Model

local Overrides = Model:extend('group_overrides', {
  relations = {
    { 'channel', belongs_to = 'channels' }
  },
  primary_key = { 'channel_id', 'group_id' }
})

return Overrides