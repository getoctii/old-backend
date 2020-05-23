local Channels = require 'models.channels'
local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local helpers = require 'lapis.application'
local Messages = require 'models.messages'

local inspect = require 'inspect'

local uuid = require 'util.uuid'
local map = require 'util.map'
local db = require 'lapis.db'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), 'ChannelNotFound')
  assert(channel:delete())
  assert(db.delete('messages', 'channel_id = ?', self.params.id))

  return {}
end
