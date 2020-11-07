local helpers = require 'lapis.application'
local broadcast = require 'util.broadcast'
local VoiceSessions = require 'models.voice_sessions'
local validate = require 'lapis.validate'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local session = helpers.assert_error(VoiceSessions:find({ id = self.params.id }), { 404, 'SessionNotFound' })
  helpers.assert_error(session.recipient_id == self.user_id or session.user_id == self.user_id, { 403, 'NotAllowed' })

  session:delete()

  if session.user_id == self.user_id then
    broadcast('user:' .. session.recipient_id, 'DELETED_VOICE_SESSION', {
      id = session.id
    })
  else
    broadcast('user:' .. session.user_id, 'DELETED_VOICE_SESSION', {
      id = session.id
    })
  end

  return {
    layout = false
  }
end