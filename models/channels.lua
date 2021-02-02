local model = require('lapis.db.model')
local Model, enum = model.Model, model.enum

local Channels = Model:extend('channels', {
  relations = {
    { 'messages', has_many = 'messages' },
    { 'community', belongs_to = 'communities' },
    { 'conversation', has_one = 'conversations' },
    { 'category', belongs_to = 'channels' }
  }
})

Channels.types = enum {
  TEXT = 1,
  CATEGORY = 2,
  CUSTOM = 3
}

return Channels
