local validate = require 'lapis.validate'
local Communities = require 'models.communities'
local helpers = require 'lapis.application'
local ChannelsModel = require 'models.channels'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'

local Channels = {}

function Channels:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'},
    { 'name', exists = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, 'ChannelNameInvalid'}
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(community.owner_id == self.user_id, { 403, 'MissingPermissions' })

  local channel = ChannelsModel:create({
    id = uuid(),
    name = self.params.name,
    community_id = community.id
  })

  broadcast('community:' .. community.id, 'NEW_CHANNEL', {
    id = channel.id,
    name = channel.name,
    community_id = channel.community_id
  })

  resubscribe('community:' .. community.id)

  return {
    json = {
      id = channel.id,
      name = channel.name
    }
  }
end

return Channels