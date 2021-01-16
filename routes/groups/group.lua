local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Groups = require 'models.groups'
local map = require 'array'.map
local contains = require 'array'.includes
local is_empty = require 'array'.is_empty
local json = require 'cjson'
local Set = require 'pl.Set'
local C = require 'pl.comprehension'.new()
local db = require 'lapis.db'
local inspect = require 'inspect'
local broadcast = require 'util.broadcast'

local permission_set = Set(C 'x for x=1,17' ())

local Group = {}

function Group:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })

  local group = helpers.assert_error(Groups:find({ id = self.params.id }), { 404, 'GroupNotFound' })
  helpers.assert_error(contains(map(group:get_community():get_members(), function(member)
    return member.user_id
  end), self.user_id), { 403, 'MissingPermissions' })
  
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
  -- TODO OMEGA WTF ALERT, THE FUCKER ISN'T VALIDATING PROPERLY
  -- https://github.com/leafo/lapis/blob/7677939eac27256c44363db974b481916c59d4da/lapis/validate.moon#L8
  -- When optional and exists are set to true, lapis calls the exists validator to check if it's optional or note
  -- Issue is, exists validator returns false on an empty string OOPS.
  -- we could probally override it?
  -- it would be preferrable to file an issue
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'name', exists = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, optional = true, 'InvalidName' },
    { 'color', exists = true, is_color = true, optional = true, 'InvalidColor' },
    { 'permissions', exists = true, optional = true, 'InvalidPermissions' }
  })
  if self.params.permissions ~= nil then
    helpers.assert_error(type((self.params.permissions) == 'table') and ((Set(self.params.permissions) + permission_set) == permission_set), { 400, 'InvalidPermissions' })
  end

  local group = helpers.assert_error(Groups:find({ id = self.params.id }), { 404, 'GroupNotFound' })
  helpers.assert_error(group:get_community().owner_id == self.user_id, { 403, 'MissingPermissions' })
  inspect(Set.values(self.params.permissions))
  group:update({
    name = self.params.name,
    color = self.params.color,
    permissions = self.params.permissions and db.array(Set.values(self.params.permissions)) or nil
  })
  group:refresh()
  inspect(group)
  local group_event = {
    id = group.id,
    name = group.name,
    color = group.color,
    permissions = is_empty(group.permissions) and json.empty_array or group.permissions
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
  helpers.assert_error(group:get_community().owner_id == self.user_id, { 403, 'MissingPermissions' })
  assert(db.delete('groups', { id = group.id }))

  broadcast('community:' .. group.community_id, 'DELETED_GROUP', {
    id = group.id,
    community_id = group.community_id
  })
  return {
    layout = false
  }
end

return Group