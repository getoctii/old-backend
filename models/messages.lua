local Model = require('lapis.db.model').Model

local Messages = Model:extend('messages', {
  relations = {
    { 'author', belongs_to = 'users' },
    { 'channel', belongs_to = 'channel' }
  }
})

return Messages
