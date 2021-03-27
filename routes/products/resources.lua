local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local array = require 'array'
local json = require 'cjson'
local ProductsModel = require 'models.products'
local ResourcesModel = require 'models.resources'
local uuid = require 'util.uuid'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

local Resources = {}

function Resources:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = product.organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  local resources = array.map(product:get_resources(), function(resource)
    return resource.id
  end)

  return {
    json = array.is_empty(resources) and json.empty_array or resources
  }
end

function Resources:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.community_name,
    type = custom_types.resource_type
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = product.organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  local resource = ResourcesModel:create({
    id = uuid(),
    name = params.name,
    type = params.type,
    product_id = product.id
  })

  return {
    status = 201,
    json = {
      id = resource.id,
      name = resource.name,
      type = resource.type
    }
  }
end

return Resources