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

local permission_set = Set(C 'x for x=1,17' ())

local Groups = {}
local inspect = require 'inspect'
function Groups:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  local groups = map(community:get_groups(), function(row)
    return {
      id = row.id
    }
  end)

  return {
    json = empty(groups) and json.empty_array or groups
  }
end

function Groups:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'},
    { 'name', exists = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, 'GroupNameInvalid' },
    { 'permissions', exists = true, optional = true, 'InvalidPermissions' }
  })

    local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
    helpers.assert_error(community.owner_id == self.user_id, { 403, 'MissingPermissions' })


    if self.params.permissions ~= nil then
      helpers.assert_error(type((self.params.permissions) == 'table') and ((Set(self.params.permissions) + permission_set) == permission_set), { 400, 'InvalidPermissions' })
    end
    inspect(self.params.permissions)
    local group = GroupsModel:create({
      id = uuid(),
      name = self.params.name,
      community_id = community.id,
      permissions = self.params.permissions and db.array(Set.values(self.params.permissions)) or nil
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

return Groups