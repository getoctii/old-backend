local Set = require 'pl.Set'
local array = require 'array'
local preload = require 'lapis.db.model'.preload
local GroupsModel = require 'models.groups'
local OverridesModel = require 'models.overrides'
local engine = {}

function engine.sum(permission_sets)
  return array.reduce(permission_sets, function(a, b)
    return a + b
  end, Set())
end

function engine.get_override_map(channel)
  local overrides = OverridesModel:select('WHERE channel_id = ?', channel.id) or {}
  local mapped = {}

  if overrides then
    for _, override in ipairs(overrides) do
      mapped[override.group_id] = {
        allow = override.allow,
        deny = override.deny
      }
    end
  end

  return mapped
end

function engine.calculate_total_overrides(channel, groups)
  local overrides = engine.get_override_map(channel)

  local mapped_overrides = array.map(groups, function(group)
    local override = overrides[group.id]

    if override then
      return {
        allow = Set(override.allow),
        deny = Set(override.deny)
      }
    end

    return nil
  end)

  local accumulated_overrides = array.reduce(mapped_overrides, function(a, b)
    return {
      allow = a.allow + b.allow,
      deny = a.deny + b.deny
    }
  end, { allow = Set(), deny = Set() })

  return accumulated_overrides
end

function engine.retrieve_groups(member)
  local group_members = member:get_group_members()
  preload(group_members, 'group')

  local groups = array.map(group_members, function(group_member)
    return group_member:get_group()
  end)

  table.sort(groups, function(a, b)
    return a.order < b.order
  end)

  return groups
end

function engine.retrieve_permissions(member)
  local community = member:get_community()
  local groups = engine.retrieve_groups(member)

  local total_permissions = Set(community.base_permissions) + engine.sum(array.map(groups, function(group)
    return Set(group.permissions)
  end))

  return total_permissions
end

function engine.has_community_permissions(member, permissions, channel)
  local community = member:get_community()

  if member.user_id == community.owner_id then
    return true
  end

  local total_permissions = engine.retrieve_permissions(member)

  if total_permissions[GroupsModel.permissions.ADMINISTRATOR] or total_permissions[GroupsModel.permissions.OWNER] then
    return true
  end

  if channel then
    local groups = engine.retrieve_groups(member)

    if channel.parent_id then
      local parent = channel:get_parent()

      total_permissions = total_permissions + Set(parent.base_allow) - Set(parent.base_deny)

      local accumulated_overrides = engine.calculate_total_overrides(parent, groups)
      total_permissions = total_permissions + accumulated_overrides.allow - accumulated_overrides.deny
    end

    total_permissions = total_permissions + Set(channel.base_allow) - Set(channel.base_deny)

    local accumulated_overrides = engine.calculate_total_overrides(channel, groups)
    total_permissions = total_permissions + accumulated_overrides.allow - accumulated_overrides.deny
  end

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

  if member_permissions[GroupsModel.permissions.ADMINISTRATOR] or member_permissions[GroupsModel.permissions.OWNER] then
    return true
  end

  return total_changes < member_permissions
end

return engine