local helpers = require 'lapis.application'
local Users = require 'models.users'
local preload = require 'lapis.db.model'.preload

local map = require 'util.map'

return function(self)
  local user = helpers.assert_error(Users:find({ id = self.user_id }), { 404, 'UserNotFound' }) -- TODO: currently we don't have a check on auth if the user exists, we should do that soon. For now we can do this
  -- local members = user:get_members()
  -- preload(members, { community = 'channels' })

  -- local communities = map(members, function(row) return row:get_community() end)
  -- local channels = flatten(map(communities, function(row) return row:get_channels() end ))
  -- local grip_channels = map(channels, function(row) return 'channel:' .. row.id end)
  local participants = user:get_participants()
  preload(participants, { conversation = 'channel' })

  local channels = map(participants, function(row) return row:get_conversation():get_channel() end)
  local grip_channels = map(channels, function(row) return 'channel:' .. row.id end)
  table.insert(grip_channels, 'user:' .. user.id)

  return {
    headers = {
      ['Grip-Hold'] = 'stream',
      ['Grip-Channel'] = table.concat(grip_channels, ','),
      ['Content-Type'] = 'text/event-stream',
      ['Grip-Keep-Alive'] = '\\n; format=cstring; timeout=30',
      ['Grip-Link'] = string.format('</events/subscribe?authorization=%s>; rel=next', self.req.headers.Authorization or self.params.authorization) -- TODO: Make this wayyy less hacky
    }
  }
end
