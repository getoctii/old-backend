local Model = require('lapis.db.model').Model

local Conversations = Model:extend('conversations', {
  relations = {
    { 'channel', belongs_to = 'channels' },
    { 'voice_channel', belongs_to = 'channels' },
    { 'participants', has_many = 'participants' }
  }
})

return Conversations
