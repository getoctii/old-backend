local Model = require('lapis.db.model').Model

local Participants = Model:extend('participants', {
  relations = {
    { 'user', belongs_to = 'users' },
    { 'conversation', belongs_to = 'conversations' }
  }
})

return Participants
