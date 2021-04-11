local Users = require 'models.users'
local helpers = require 'lapis.application'
local preload = require 'lapis.db.model'.preload
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local array = require 'array'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

local json = require 'cjson'

local map = require 'array'.map
local empty = require 'array'.is_empty

local Organizations = {}

function Organizations:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local members = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' }):get_members()
  preload(members, 'community')

  local organizations = map(
  array.filter(members, function(member)
    return engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })) and member:get_community().organization
  end),
  function(row)
    local community = row:get_community()
    return {
      id = community.id,
      name = community.name
    }
  end)

  if empty(organizations) then
    organizations = json.empty_array
  end

  return {
    json = organizations
  }
end

return Organizations