local preload = require 'lapis.db.model'.preload
local map = require 'array'.map
local flatten = require 'array'.flat

return function(user)
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

  return all_grip_channels
end