local model = require('lapis.db.model')
local Model, enum = model.Model, model.enum

local Messages = Model:extend('messages', {
  timestamp = true,
  relations = {
    { 'author', belongs_to = 'users' },
    { 'channel', belongs_to = 'channels' }
  }
})

Messages.types = enum {
  normal = 1,
  pinned = 2,
  member_added = 3,
  member_removed = 4,
  administrator = 5,
  webhook = 6,
  integration = 7
}

return Messages
