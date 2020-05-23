local helpers = require 'lapis.application'
local validate = require 'lapis.validate'

local Channels = require 'models.channels'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), 'ChannelNotFound')

  return {
    json = {
      name = channel.name,
      community_id = channel.community_id
    }
  }
end