local Model = require('lapis.db.model').Model

local Read = Model:extend('read', {
  relations = {
    { 'user', belongs_to = 'users' },
    { 'channel', belongs_to = 'users' },
    { 'last_read', belongs_to = 'users' }
  }
})

return Read
