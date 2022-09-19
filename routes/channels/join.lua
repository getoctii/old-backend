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
local jwt = require 'resty.jwt'
local array = require 'array'
local broadcast = require 'util.broadcast'

local Join = {}

local function to_pairs(tbl)
  local output = {}

  for i, v in pairs(tbl) do
    table.insert(output, {i, v})
  end

  return output
end

local function generate_voice_token(room_id, user_id)
  local time = os.time()

  local table = {
    header = {
      typ = 'JWT',
      alg = 'RS256'
    },
    payload = {
      iss = 'gateway.octii.chat',
      aud = 'voice.octii.chat',
      sub = user_id,
      iat = time,
      nbf = time,
      exp = time + 30,
      room = room_id
    }
  }

  return jwt:sign(config.jwt.voice, table)
end

function Join:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    last_message_id = custom_types.uuid:is_optional()
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 3, { 400, 'ChannelNotVoice' })

  if not channel.community_id then
    helpers.assert_error(array.includes(array.map(channel:get_voice_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES }), channel), { 403, 'MissingPermissions' })
  end


  local room = VoiceRooms:find({
    channel_id = channel.id
  })

  if not channel.community_id then
    local conversation = channel:get_voice_conversation()
    if (not room) or #room.users == 0 then
      local users = array.map(conversation:get_participants(), function (row)
        return row.user_id
      end)

      for _, id in ipairs(array.without(users, { self.user.id })) do
        broadcast('user:' .. id, 'RINGING', {
          conversation_id = conversation.id
        })
      end
    end
  end

  if room then
    return {
      json = {
        server = config.voice_servers[room.server].public_url,
        room_id = room.id,
        token = generate_voice_token(room.id, self.user.id)
      }
    }
  else
    local voice_pairs = to_pairs(config.voice_servers)
    local pair = voice_pairs[math.random(#voice_pairs)]

    local token = config.voice_token

    local httpc = assert(http.new())

    local res = assert(httpc:request_uri(pair[2].private_url .. '/rooms', {
      method = 'POST',
      headers = {
        ['Authorization'] = token
      }
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
        token = generate_voice_token(room.id, self.user.id)
      }
    }
  end
end

return Join