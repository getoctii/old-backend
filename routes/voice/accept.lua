local helpers = require 'lapis.application'
local broadcast = require 'util.broadcast'
local VoiceSessions = require 'models.voice_sessions'
local validate = require 'lapis.validate'

local Accept = {}

function Accept:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'peer_id', exists = true, 'InvalidPeerID'}
  })

  local session = helpers.assert_error(VoiceSessions:find({ id = self.params.id }), { 404, 'SessionNotFound' })
  helpers.assert_error(session.recipient_id == self.user.id, { 403, 'NotAllowed' })

  broadcast('user:' .. session.user_id, 'ACCEPTED_VOICE_SESSION', {
    id = session.id,
    peer_id = self.params.peer_id
  })

  return {
    layout = false
  }
end

return Accept