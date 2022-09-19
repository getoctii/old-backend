local model = require('lapis.db.model')
local Model, enum = model.Model, model.enum

local Channels = Model:extend('channels', {
  relations = {
    { 'messages', has_many = 'messages' },
    { 'community', belongs_to = 'communities' },
    { 'conversation', has_one = 'conversations' },
    { 'voice_conversation', has_one = 'conversations', key = 'voice_channel_id' },
    { 'parent', belongs_to = 'channels' },
    { 'children', has_many = 'channels', key = 'parent_id' }
  }
})

Channels.types = enum {
  TEXT = 1,
  CATEGORY = 2,
  VOICE = 3,
  CUSTOM = 4
}

return Channels
