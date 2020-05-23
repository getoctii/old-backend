local Communities = require 'models.communities'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Channels = require 'models.channels'

local uuid = require 'util.uuid'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'name', exists = true, min_length = 2, max_length = 16, 'ChannelNameInvalid' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), 'CommunityNotFound')

  local channel = Channels:create({
    id = uuid(),
    name = self.params.name,
    community_id = community.id
  })

  return {
    json = {
      id = channel.id,
      name = channel.name
    }
  }
end