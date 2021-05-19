local preload = require 'lapis.db.model'.preload
local map = require 'array'.map
local flatten = require 'array'.flat
local filter = require 'array'.filter
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

return function(user)
  local members = user:get_members()
  preload(members, { community = 'channels' })
  preload(members, 'group_members')

  local communities = map(members, function(row) return row:get_community() end)
  local grip_communities = map(communities, function (row) return 'community:' .. row.id end)
  local community_channels = flatten(map(members, function(member)
    if engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES })) then
      return filter(member:get_community():get_channels(), function(channel)
        return engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES }), channel)
      end)
    else
      return {}
    end
  end))

  local grip_groups = flatten(map(members, function(member)
    return map(member:get_group_members(), function(group_member)
      return 'group:' .. group_member.group_id
    end)
  end))

  local grip_community_channels = map(community_channels, function(row) return 'channel:' .. row.id end)

  local participants = user:get_participants()
  preload(participants, { conversation = 'channel' })

  local conversations = map(participants, function(row) return row:get_conversation() end)
  local grip_conversations = map(conversations, function(row) return 'conversation:' .. row.id end)

  local grip_conversation_channels = map(conversations, function(row) return 'channel:' .. row.channel_id end)
  local grip_conversation_voice_channels = map(conversations, function(row) return 'channel:' .. row.voice_channel_id end)

  local all_grip_channels = flatten({grip_community_channels, grip_conversation_channels, grip_communities, grip_conversations, grip_conversation_voice_channels, grip_groups, {'user:' .. user.id}})

  return all_grip_channels
end