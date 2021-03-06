local helpers = require 'lapis.application'
local broadcast = require 'util.broadcast'
local VoiceSessions = require 'models.voice_sessions'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Accept = {}

function Accept:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    peer_id = types.string
  })

  local session = helpers.assert_error(VoiceSessions:find({ id = params.id }), { 404, 'SessionNotFound' })
  helpers.assert_error(session.recipient_id == self.user.id, { 403, 'NotAllowed' })

  broadcast('user:' .. session.user_id, 'ACCEPTED_VOICE_SESSION', {
    id = session.id,
    peer_id = params.peer_id
  })

  return {
    layout = false
  }
end

return Accept