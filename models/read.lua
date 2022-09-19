local Model = require('lapis.db.model').Model

local Read = Model:extend('read', {
  primary_key = { 'user_id', 'channel_id' },
  relations = {
    { 'user', belongs_to = 'users' },
    { 'channel', belongs_to = 'channels' },
    { 'last_read', belongs_to = 'messages' }
  }
})

return Read
