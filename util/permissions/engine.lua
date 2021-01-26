local Set = require 'pl.Set'
local MembersModel = require 'models.members'
local array = require 'array'
local preload = require 'lapis.db.model'.preload
local engine = {}

function engine.sum(permission_sets)
  return array.reduce(permission_sets, function(a, b)
    return a + b
  end, Set())
end

function engine.has_community_permissions(member_id, permissions)
  local member = MembersModel:find(member_id)
  local group_members = member:get_group_members()
  preload(group_members, 'group')

  local groups = array.map(group_members, function(group_member)
    return group_member:get_group()
  end)

  local total_permissions = engine.sum(array.map(groups, function(group)
    return Set(group.permissions)
  end))

  return permissions < total_permissions
end
-- ur cutting out badly lmao member list? yes thats for later
-- prob gonna display the top roles you can fit in ur screen then have a ... button that has a popup with the other roles u can manage simialr to discords member list
return engine