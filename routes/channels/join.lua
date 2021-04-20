local ChannelsModel = require 'models.channels'
local GroupsModel = require 'models.groups'
local MembersModel = require 'models.members'
local helpers = require 'lapis.application'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local VoiceRooms = require 'models.voice_rooms'
local http = require 'resty.http'
local json = require 'cjson'
local config = require 'lapis.config'.get()

local Join = {}

local function to_pairs(tbl)
  local output = {}

  for i, v in pairs(tbl) do
    table.insert(output, {i, v})
  end

  return output
end

function Join:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    last_message_id = custom_types.uuid:is_optional()
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 3, { 400, 'ChannelNotVoice' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES }), channel), { 403, 'MissingPermissions' })

  local room = VoiceRooms:find({
    channel_id = channel.id
  })

  if room then
    return {
      json = {
        server = config.voice_servers[room.server].public_url,
        room_id = room.id,
        token = nil
      }
    }
  else
    local voice_pairs = to_pairs(config.voice_servers)
    local pair = voice_pairs[math.random(#voice_pairs)]

    local httpc = assert(http.new())

    local res = assert(httpc:request_uri(pair[2].private_url .. '/rooms', {
      method = 'POST',
    }))

    assert(res.status == 200)

    local body = json.decode(res.body)

    local room = VoiceRooms:create({
      id = body.id,
      server = pair[1],
      channel_id = channel.id
    })

    return {
      json = {
        server = config.voice_servers[room.server].public_url,
        room_id = room.id,
        token = nil
      }
    }
  end
end

return Join