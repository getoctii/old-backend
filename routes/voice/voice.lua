local helpers = require 'lapis.application'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local Users = require 'models.users'
local VoiceSessions = require 'models.voice_sessions'
local validate = require 'lapis.validate'

local Voice = {}

function Voice:POST()
  validate.assert_valid(self.params, {
    { 'recipient', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'peer_id', exists = true, 'InvalidPeerID'}
  })

  local recipient = helpers.assert_error(Users:find({ id = self.params.recipient }), { 404, 'RecipientNotFound' })
  local session = assert(VoiceSessions:create({
    id = uuid(),
    user_id = self.user.id,
    recipient_id = recipient.id
  }))

  broadcast('user:' .. recipient.id, 'NEW_VOICE_SESSION', {
    id = session.id,
    user_id = session.user_id,
    peer_id = self.params.peer_id
  })

  return {
    json = {
      id = session.id
    }
  }
end

return Voice