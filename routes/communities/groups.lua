local Communities = require 'models.communities'
local helpers = require 'lapis.application'
local broadcast = require 'util.broadcast'
local uuid = require 'util.uuid'
local GroupsModel = require 'models.groups'
local map = require 'array'.map
local empty = require 'array'.is_empty
local filter = require 'array'.filter
local slice = require 'array'.slice
local every = require 'array'.every
local json = require 'cjson'
local Set = require 'pl.Set'
local C = require 'pl.comprehension'.new()
local db = require 'lapis.db'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local resubscribe = require 'util.resubscribe'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

-- TODO: Non-atomic, is there some pure SQL way of doing this
local function reorder_groups(order)
  for i, v in ipairs(order) do
    local group = GroupsModel:find({ id = v })
    group:update({
      order = i
    })
  end
end

local function array_equal(a1, a2)
  if #a1 ~= #a2 then return false end
  return every(a1, function(element, index)
    return element == a2[index]
  end)
end

local function sort_groups(groups)
  table.sort(groups, function(a, b)
    return a.order < b.order
  end)
end

local Groups = {}

function Groups:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  -- TODO: Maybe sort in SQL?
  local groups = community:get_groups()
  sort_groups(groups)

  local mapped_groups = map(groups, function(row)
    return row.id
  end)

  return {
    json = empty(mapped_groups) and json.empty_array or mapped_groups
  }
end

function Groups:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.group_name,
    permissions = custom_types.permissions:is_optional()
  })

    local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })

    local member = helpers.assert_error(MembersModel:find({
      community_id = community.id,
      user_id = self.user.id
    }), { 404, 'CommunityNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_GROUPS })), { 403, 'MissingPermissions' })

    if params.permissions ~= nil then
      helpers.assert_error(engine.has_community_permissions(member, params.permissions), { 403, 'MissingPermissions' })
    end

    local groups = community:get_groups()
    sort_groups(groups)

    local group = GroupsModel:create({
      id = uuid(),
      name = params.name,
      community_id = community.id,
      permissions = params.permissions and (#params.permissions == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.permissions))) or nil
    })

    reorder_groups({ group.id, unpack(map(groups, function(row)
      return row.id
    end)) })

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
  local params = validate(self.params, types.shape {
    order = types.array_of(types.string):is_optional()
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_GROUPS })), { 403, 'MissingPermissions' })

  if params.order then
    helpers.assert_error(Set(params.order) == Set(map(community:get_groups(), function(row) return row.id end)), { 400, 'InvalidOrder' })

    if not engine.has_community_permissions(member, Set({ GroupsModel.permissions.OWNER })) then
      local groups = community:get_groups()
      sort_groups(groups)
      local highest_order = engine.get_highest_order(member)
      local protected_groups = map(filter(groups, function(group)
        return group.order >= highest_order
      end), function (group)
        return group.id
      end)

      if #protected_groups > 0 then
        helpers.assert_error(array_equal(slice(params.order, (#params.order - #protected_groups) + 1), protected_groups), { 403, 'MissingPermissions' })
      end
    end

    reorder_groups(params.order)

    -- lmao lag
    resubscribe('community:' .. community.id)

    broadcast('community:' .. community.id, 'REORDERED_GROUPS', {
      community_id = community.id,
      order = params.order
    })
  end

  return {
    status = 204,
    layout = false
  }
end

return Groups