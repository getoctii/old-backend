local validate = require 'lapis.validate'
local Communities = require 'models.communities'
local helpers = require 'lapis.application'
local broadcast = require 'util.broadcast'
local uuid = require 'util.uuid'
local GroupsModel = require 'models.groups'
local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'
local Set = require 'pl.Set'
local C = require 'pl.comprehension'.new()
local db = require 'lapis.db'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'

local permission_set = Set(C 'x for x=1,17' ())

local Groups = {}

function Groups:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  local groups = community:get_groups()

  table.sort(groups, function(a, b)
    return a.order < b.order
  end)

  local mapped_groups = map(groups, function(row)
    return {
      id = row.id
    }
  end)

  return {
    json = empty(mapped_groups) and json.empty_array or mapped_groups
  }
end

function Groups:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'},
    { 'name', exists = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, 'GroupNameInvalid' },
    { 'permissions', exists = true, optional = true, 'InvalidPermissions' }
  })

    local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

    local member = helpers.assert_error(MembersModel:find({
      community_id = community.id,
      user_id = self.user.id
    }), { 404, 'CommunityNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, { GroupsModel.permissions.MANAGE_PERMISSIONS }), { 403, 'MissingPermissions' })

    if self.params.permissions ~= nil then
      helpers.assert_error(type((self.params.permissions) == 'table') and ((Set(self.params.permissions) + permission_set) == permission_set), { 400, 'InvalidPermissions' })
      helpers.assert_error(engine.has_community_permissions(member, self.params.permissions), { 403, 'MissingPermissions' })
    end

    local group = GroupsModel:create({
      id = uuid(),
      name = self.params.name,
      community_id = community.id,
      permissions = self.params.permissions and (empty(self.values.permissions) and db.raw('array[]::integer[]') or db.array(Set.values(Set(self.params.permissions)))) or nil
    })

    broadcast('community:' .. community.id, 'NEW_GROUP', {
      id = group.id,
      community_id = group.community_id
    })

    return {
      json = {
        id = group.id,
        name = group.name
      }
    }
end

function Groups:PATCH()
  validate.assert_valid(self.params, {
    { 'order', exists = true, optional = true, 'InvalidOrder' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, { GroupsModel.permissions.MANAGE_PERMISSIONS }), { 403, 'MissingPermissions' })
  -- Enforce heirachy on reorder
  if self.params.order then
    helpers.assert_error(Set(self.params.order) == Set(map(community:get_groups(), function(row) return row.id end)), { 400, 'InvalidOrder' })
    for i, v in ipairs(self.params.order) do
      local group = helpers.assert_error(GroupsModel:find({ id = v }), { 404, 'GroupNotFound'})
      helpers.assert_error(community.id == group.community_id,  {404, 'GroupNotFound' })

      group:update({
        order = i
      })
    end
  end

  return {
    status = 204,
    layout = false
  }
end

return Groups