local preload = require 'lapis.db.model'.preload
local map = require 'array'.map
local flatten = require 'array'.flat
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

return function(user)
  local members = user:get_members()
  preload(members, { community = 'channels' })

  local communities = map(members, function(row) return row:get_community() end)
  local grip_communities = map(communities, function (row) return 'community:' .. row.id end)
  local community_channels = flatten(map(members, function(member)
    if engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES })) then
      return member:get_community():get_channels()
    else
      return {}
    end
  end))
  local grip_community_channels = map(community_channels, function(row) return 'channel:' .. row.id end)

  local participants = user:get_participants()
  preload(participants, { conversation = 'channel' })

  local conversations = map(participants, function(row) return row:get_conversation() end)
  local grip_conversations = map(conversations, function(row) return 'conversation:' .. row.id end)

  local conversation_channels = map(participants, function(row) return row:get_conversation():get_channel() end)
  local grip_conversation_channels = map(conversation_channels, function(row) return 'channel:' .. row.id end)

  local all_grip_channels = flatten({grip_community_channels, grip_conversation_channels, grip_communities, grip_conversations, {'user:' .. user.id}})

  return all_grip_channels
end