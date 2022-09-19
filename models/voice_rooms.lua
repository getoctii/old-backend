local model = require('lapis.db.model')
local Model = model.Model

local VoiceRooms = Model:extend('voice_rooms', {
  relations = {
    { 'channel', belongs_to = 'channels' }
  }
})

return VoiceRooms
