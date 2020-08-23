local Model = require('lapis.db.model').Model

local Channels = Model:extend('channels', {
  relations = {
    { 'messages', has_many = 'messages' },
    { 'community', belongs_to = 'communities' },
    { 'conversation', has_one = 'conversations' }
  }
})

return Channels
