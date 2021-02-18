local helpers = require 'lapis.application'
local Users = require 'models.users'

local map = require 'array'.map
local validate = require 'lapis.validate'

local broadcast_multiple = require 'util.broadcast_multiple'
local generate_grip_channels = require 'util.generate_grip_channels'

local Subscribe = {}

function Subscribe:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.user.id == self.params.id, { 403, 'NotAllowed' })

  local all_grip_channels = generate_grip_channels(self.user)

  self.user:update {
    last_ping = os.time()
  }

  -- user:refresh()

  -- local broadcast_payload = {
  --   id = user.id,
  --   state = Users.states:to_name(user.state),
  -- }

  -- -- might be redundant but
  -- if (not user.last_ping) or ((os.time() - user.last_ping) > 180) then
  --   broadcast_payload.state = 'offline'
  -- end

  -- -- TODO: Maybe don't broadcast if user is invis?
  -- broadcast_multiple(all_grip_channels, 'UPDATED_USER', broadcast_payload)

  return {
    layout = false,
    headers = {
      ['Grip-Hold'] = 'stream',
      ['Grip-Channel'] = table.concat(all_grip_channels, ','),
      ['Content-Type'] = 'text/event-stream',
      ['Grip-Keep-Alive'] = '\\n; format=cstring; timeout=30',
      ['Grip-Link'] = string.format('</events/subscribe/%s?authorization=%s>; rel=next', self.user.id, self.req.headers.Authorization or self.params.authorization) -- TODO: Make this wayyy less hacky
    }
  }
end

return Subscribe
