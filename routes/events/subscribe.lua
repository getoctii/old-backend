local helpers = require 'lapis.application'
local Users = require 'models.users'
local preload = require 'lapis.db.model'.preload

local map = require 'array'.map
local flatten = require 'array'.flat
local validate = require 'lapis.validate'

local Subscribe = {}

function Subscribe:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.user_id == self.params.id, { 403, 'NotAllowed' })
  local user = helpers.assert_error(Users:find({ id = self.user_id }), { 404, 'UserNotFound' }) -- TODO: currently we don't have a check on auth if the user exists, we should do that soon. For now we can do this
  local members = user:get_members()
  preload(members, { community = 'channels' })

  local communities = map(members, function(row) return row:get_community() end)
  local grip_communities = map(communities, function (row) return 'community:' .. row.id end)
  local community_channels = flatten(map(communities, function(row) return row:get_channels() end ))
  local grip_community_channels = map(community_channels, function(row) return 'channel:' .. row.id end)

  local participants = user:get_participants()
  preload(participants, { conversation = 'channel' })

  local conversations = map(participants, function(row) return row:get_conversation() end)
  local formatted_conversations = map(conversations, function(row) return 'conversation:' .. row.id end)

  local channels = map(participants, function(row) return row:get_conversation():get_channel() end)
  local grip_channels = map(channels, function(row) return 'channel:' .. row.id end)

  local all_grip_channels = flatten({grip_community_channels, grip_channels, grip_communities, formatted_conversations, {'user:' .. user.id}})

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