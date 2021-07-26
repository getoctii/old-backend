local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local Set = require 'pl.Set'
local VoiceRooms = require 'models.voice_rooms'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
local json = require 'cjson'
local broadcast = require 'util.broadcast'
local Channels = require 'models.channels'
local config = require 'lapis.config'.get()
local Users = {}

function Users:PUT()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    user_id = custom_types.uuid
  })

  local token = config.voice_token

  helpers.assert_error(self.req.headers.Authorization == token, { 403, 'Unauthorized' })

  local room = helpers.assert_error(VoiceRooms:find(params.id), { 404 , 'RoomNotFound' })
  local users = Set(room.users) + Set({ params.user_id })

  room:update({
    users = #users == 0 and db.raw('array[]::text[]') or db.array(Set.values(users))
  })

  local channel = Channels:find(room.channel_id)

  broadcast('channel:' .. room.channel_id, 'UPDATED_CHANNEL', {
    id = room.channel_id,
    community_id = channel.community_id,
    voice_users = #users == 0 and json.empty_array or Set.values(users)
  })

  return {
    layout = false
  }
end

function Users:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    user_id = custom_types.uuid
  })

  local room = helpers.assert_error(VoiceRooms:find(params.id), { 404 , 'RoomNotFound' })
  local users = Set(room.users) - Set({ params.user_id })

  room:update({
    users = #users == 0 and db.raw('array[]::text[]') or db.array(Set.values(users))
  })

  local channel = Channels:find(room.channel_id)

  broadcast('channel:' .. room.channel_id, 'UPDATED_CHANNEL', {
    id = room.channel_id,
    community_id = channel.community_id,
    voice_users = #users == 0 and json.empty_array or Set.values(users)
  })

  return {
    layout = false
  }
end

return Users