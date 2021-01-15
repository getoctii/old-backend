local helpers = require 'lapis.application'
local Users = require 'models.users'
local preload = require 'lapis.db.model'.preload

local map = require 'array'.map
local flatten = require 'array'.flat
local validate = require 'lapis.validate'

local generate_grip_channels = require 'util.generate_grip_channels'

local Subscribe = {}

function Subscribe:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.user_id == self.params.id, { 403, 'NotAllowed' })
  local user = helpers.assert_error(Users:find({ id = self.user_id }), { 404, 'UserNotFound' }) -- TODO: currently we don't have a check on auth if the user exists, we should do that soon. For now we can do this

  local all_grip_channels = generate_grip_channels(user)

  user:update {
    last_ping = os.time()
  }

  return {
    layout = false,
    headers = {
      ['Grip-Hold'] = 'stream',
      ['Grip-Channel'] = table.concat(all_grip_channels, ','),
      ['Content-Type'] = 'text/event-stream',
      ['Grip-Keep-Alive'] = '\\n; format=cstring; timeout=30',
      ['Grip-Link'] = string.format('</events/subscribe/%s?authorization=%s>; rel=next', user.id, self.req.headers.Authorization or self.params.authorization) -- TODO: Make this wayyy less hacky
    }
  }
end

return Subscribe