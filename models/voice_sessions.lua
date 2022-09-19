local Model = require('lapis.db.model').Model

local VoiceSessions = Model:extend('voice_sessions', {
  relations = {
    { 'user', belongs_to = 'users' },
    { 'recipient', belongs_to = 'users' }
  }
})

return VoiceSessions
