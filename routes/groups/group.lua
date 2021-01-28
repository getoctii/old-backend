local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Groups = require 'models.groups'
local is_empty = require 'array'.is_empty
local json = require 'cjson'
local Set = require 'pl.Set'
local C = require 'pl.comprehension'.new()
local db = require 'lapis.db'
local broadcast = require 'util.broadcast'
local MembersModel = require 'models.members'
local CommunitiesModel = require 'models.communities'
local engine = require 'util.permissions.engine'
local empty = require 'array'.is_empty

local permission_set = Set(C 'x for x=1,17' ())

local Group = {}

function Group:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })

  local group = helpers.assert_error(Groups:find({ id = self.params.id }), { 404, 'GroupNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'GroupNotFound' })

  return {
    json = {
      id = group.id,
      name = group.name,
      color = group.color,
      permissions = is_empty(group.permissions) and json.empty_array or group.permissions
    }
  }
end

function Group:PATCH()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'name', exists = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, optional = true, 'InvalidName' },
    { 'color', exists = true, is_color = true, optional = true, 'InvalidColor' },
    { 'permissions', exists = true, optional = true, 'InvalidPermissions' }
  })

  local group = helpers.assert_error(Groups:find({ id = self.params.id }), { 404, 'GroupNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'GroupNotFound' })

  local community = CommunitiesModel:find(group.community_id)

  helpers.assert_error(engine.has_community_permissions(member, { Groups.permissions.MANAGE_PERMISSIONS }), { 403, 'MissingPermissions' })
  helpers.assert_error((community.owner_id == self.user.id) or (engine.get_highest_order(member) > group.order) , { 403, 'MissingPermissions' })

  if self.params.permissions ~= nil then
    helpers.assert_error(type((self.params.permissions) == 'table') and ((Set(self.params.permissions) + permission_set) == permission_set), { 400, 'InvalidPermissions' })
    helpers.assert_error(engine.has_community_permissions(member, self.params.permissions), { 403, 'MissingPermissions' })
  end

  group:update({
    name = self.params.name,
    color = self.params.color,
    permissions = self.params.permissions and (empty(self.values.permissions) and db.raw('array[]::integer[]') or db.array(Set.values(Set(self.params.permissions)))) or nil
  })

  group:refresh()

  local group_event = {
    id = group.id,
    name = group.name,
    color = group.color,
    permissions = is_empty(group.permissions) and json.empty_array or group.permissions,
    community_id = group.community_id
  }

  broadcast('community:' .. group.community_id, 'UPDATED_GROUP', group_event)
  return {
    status = 204,
    layout = false
  }
end

function Group:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvaildUUID' }
  })

  local group = helpers.assert_error(Groups:find({ id = self.params.id }), { 404, 'GroupNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'GroupNotFound' })

  local community = CommunitiesModel:find(group.community_id)

  helpers.assert_error(engine.has_community_permissions(member, { Groups.permissions.MANAGE_PERMISSIONS }), { 403, 'MissingPermissions' })
  helpers.assert_error((community.owner_id == self.user.id) or (engine.get_highest_order(member) > group.order) , { 403, 'MissingPermissions' })

  assert(db.delete('groups', { id = group.id }))
  assert(db.delete('group_members', { group_id = group.id }))

  broadcast('community:' .. group.community_id, 'DELETED_GROUP', {
    id = group.id,
    community_id = group.community_id
  })

  return {
    layout = false
  }
end

return Group