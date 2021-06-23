local validate = require 'util.validate'
local ResourcesModel = require 'models.resources'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

local Resources = {}

--TODO:permissions, and extra validation
function Resources:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  -- Security Issue
  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })
  if not resource:get_product().approved then
    local member = helpers.assert_error(MembersModel:find({
      community_id = resource:get_product().organization_id,
      user_id = self.user.id
    }), { 403, 'MissingPermissions' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })
  end

  return {
    json = {
      id = resource.id,
      name = resource.name,
      type = resource.type
    }
  }
end

function Resources:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid,
    name = custom_types.community_name:is_optional(),
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = resource:get_product().organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  resource:update({
    name = params.name
  })

  return {
    layout = false,
    status = 200
  }
end

function Resources:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = resource:get_product().organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })
  resource:delete()

  return {
    layout = false,
    status = 200
  }
end

return Resources