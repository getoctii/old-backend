local helpers = require 'lapis.application'
local NotifcationTokens = require 'models.notification_tokens'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Notifications = {}

function Notifications:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    token = types.string,
    platform = types.one_of { 'ios' }
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  NotifcationTokens:create({
    user_id = self.user.id,
    platform = params.platform,
    token = params.token
  })

  return {
    status = 201,
    layout = false
  }
end

return Notifications