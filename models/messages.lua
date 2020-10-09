local Model = require('lapis.db.model').Model

local Messages = Model:extend('messages', {
  timestamp = true,
  relations = {
    { 'author', belongs_to = 'users' },
    { 'channel', belongs_to = 'channels' }
  }
})

return Messages
