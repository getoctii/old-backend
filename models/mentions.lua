local Model = require('lapis.db.model').Model

local Mentions = Model:extend('mentions', {
  relations = {
    { 'message', belongs_to = 'messages' },
    { 'user', belongs_to = 'users' }
  }
})

return Mentions
