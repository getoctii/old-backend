local Channels = require 'models.channels'
local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local helpers = require 'lapis.application'
local Messages = require 'models.messages'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'

local inspect = require 'inspect'

local uuid = require 'util.uuid'
local map = require 'util.map'
local db = require 'lapis.db'


-- Handle edge case where user tries to delete DM channel.
return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), 'ChannelNotFound')
  if not channel.community_id then
    helpers.yield_error({ 400, 'InvalidChannel' })
  else
    helpers.assert_error(channel:get_community().owner_id == self.user_id, { 403, 'MissingPermissions' })
  end

  assert(channel:delete())
  assert(db.delete('messages', 'channel_id = ?', self.params.id))

  broadcast('community:' .. channel.community_id, 'DELETED_CHANNEL', {
    id = channel.id,
    community_id = channel.community_id
  })

  resubscribe('community:' .. channel.community_id)

  return {
    layout = false
  }
end
