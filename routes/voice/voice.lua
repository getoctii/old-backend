local helpers = require 'lapis.application'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local Users = require 'models.users'
local VoiceSessions = require 'models.voice_sessions'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'


local Voice = {}

function Voice:POST()
  local params = validate(self.params, types.shape {
    recipient = custom_types.uuid,
    peer_id = types.string
  })

  local recipient = helpers.assert_error(Users:find({ id = params.recipient }), { 404, 'RecipientNotFound' })
  local session = assert(VoiceSessions:create({
    id = uuid(),
    user_id = self.user.id,
    recipient_id = recipient.id
  }))

  broadcast('user:' .. recipient.id, 'NEW_VOICE_SESSION', {
    id = session.id,
    user_id = session.user_id,
    peer_id = params.peer_id
  })

  return {
    json = {
      id = session.id
    }
  }
end

return Voice