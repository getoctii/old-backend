local helpers = require 'lapis.application'
local Groups = require 'models.groups'
local is_empty = require 'array'.is_empty
local json = require 'cjson'
local Set = require 'pl.Set'
local db = require 'lapis.db'
local broadcast = require 'util.broadcast'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local resubscribe = require 'util.resubscribe'
local map = require 'array'.map
local GroupsModel = require 'models.groups'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local function reorder_groups(order)
  for i, v in ipairs(order) do
    local group = GroupsModel:find({ id = v })
    group:update({
      order = i
    })
  end
end

local function sort_groups(groups)
  table.sort(groups, function(a, b)
    return a.order < b.order
  end)
end

local Group = {}

function Group:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local group = helpers.assert_error(Groups:find({ id = params.id }), { 404, 'GroupNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'GroupNotFound' })

  return {
    json = {
      id = group.id,
      name = group.name,
      color = group.color,
      permissions = is_empty(group.permissions) and json.empty_array or group.permissions,
      order = group.order
    }
  }
end

function Group:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.group_name:is_optional(),
    color = custom_types.color:is_optional(),
    permissions = custom_types.permissions:is_optional()
  })

  local group = helpers.assert_error(Groups:find({ id = params.id }), { 404, 'GroupNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'GroupNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ Groups.permissions.MANAGE_GROUPS })), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ Groups.permissions.OWNER })) or (engine.get_highest_order(member) > group.order) , { 403, 'MissingPermissions' })

  if params.permissions ~= nil then
    helpers.assert_error(engine.can_update_permissions(member, Set(group.permissions), params.permissions), { 403, 'MissingPermissions' })
  end

  group:update({
    name = params.name,
    color = params.color,
    permissions = params.permissions and (#params.permissions == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.permissions))) or nil
  })

  group:refresh()

  local group_event = {
    id = group.id,
    name = group.name,
    color = group.color,
    permissions = is_empty(group.permissions) and json.empty_array or group.permissions,
    community_id = group.community_id
  }

  resubscribe('group:' .. group.id)
  broadcast('community:' .. group.community_id, 'UPDATED_GROUP', group_event)

  return {
    status = 204,
    layout = false
  }
end

function Group:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local group = helpers.assert_error(Groups:find({ id = params.id }), { 404, 'GroupNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'GroupNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ Groups.permissions.MANAGE_GROUPS })), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ Groups.permissions.OWNER })) or (engine.get_highest_order(member) > group.order) , { 403, 'MissingPermissions' })

  assert(db.delete('groups', { id = group.id }))
  assert(db.delete('group_members', { group_id = group.id }))

  resubscribe('group:' .. group.id)

  local groups = member:get_community():get_groups()
  sort_groups(groups)
  local group_ids = map(groups, function(row)
    return row.id
  end)
  reorder_groups(group_ids)

  broadcast('community:' .. group.community_id, 'DELETED_GROUP', {
    id = group.id,
    community_id = group.community_id
  })

  broadcast('community:' .. member.community_id, 'REORDERED_GROUPS', {
    community_id = member.community_id,
    order = group_ids
  })

  return {
    layout = false
  }
end

return Group