local Model = require('lapis.db.model').Model

local NotificationTokens = Model:extend('notification_tokens', {
  primary_key = { 'user_id', 'platform', 'token' },
  relations = {
    { 'user', belongs_to = 'users' }
  }
})

return NotificationTokens
