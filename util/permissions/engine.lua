local Set = require 'pl.Set'
local array = require 'array'
local preload = require 'lapis.db.model'.preload
local engine = {}

function engine.sum(permission_sets)
  return array.reduce(permission_sets, function(a, b)
    return a + b
  end, Set())
end

function engine.retrieve_permissions(member)
  local community = member:get_community()

  local group_members = member:get_group_members()
  preload(group_members, 'group')

  local groups = array.map(group_members, function(group_member)
    return group_member:get_group()
  end)

  local total_permissions = Set(community.base_permissions) + engine.sum(array.map(groups, function(group)
    return Set(group.permissions)
  end))

  return total_permissions
end

function engine.has_community_permissions(member, permissions)
  local community = member:get_community()

  if member.user_id == community.owner_id then
    return true
  end

  local total_permissions = engine.retrieve_permissions(member)

  return permissions < total_permissions
end

function engine.get_highest_order(member)
  local group_members = member:get_group_members()
  preload(group_members, 'group')

  local group_orders = array.map(group_members, function(group_member)
    return group_member:get_group().order
  end)

  return array.reduce(group_orders, function(a, b)
    return b > a and b or a
  end, 0)
end

function engine.can_update_permissions(member, old, new)
  local community = member:get_community()

  if member.user_id == community.owner_id then
    return true
  end

  local removed = old - new
  local added = new - old
  local total_changes = removed + added

  local member_permissions = engine.retrieve_permissions(member)

  return total_changes < member_permissions
end

return engine