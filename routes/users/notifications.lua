local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local NotifcationTokens = require 'models.notification_tokens'

local Notifications = {}

function Notifications:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'token', exists = true, 'InvalidToken' },
    { 'platform', exists = true, one_of = { 'ios' }, 'InvalidPlatform' }
  })

  helpers.assert_error(self.params.id == self.user_id, { 403, 'InvalidUser' })

  NotifcationTokens:create({
    user_id = self.user_id,
    platform = self.params.platform,
    token = self.params.token
  })

  return {
    status = 201,
    layout = false
  }
end

return Notifications