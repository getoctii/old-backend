local validate = require 'util.validate'
local types = require 'tableshape'.types
local helpers = require 'lapis.application'
local custom_types = require 'util.types'
local Communities = require 'models.communities'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'
local ProductsModel = require 'models.products'
local array = require 'array'
local json = require 'cjson'
local uuid = require 'util.uuid'

local Products = {}

function Products:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })
  helpers.assert_error(community.organization, { 403, 'MissingPermissions' })

  local products = array.map(community:get_products(), function(product)
    return product.id
  end)

  return {
    status = 200,
    json = array.is_empty(products) and json.empty_array or products
  }
end

function Products:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.community_name,
    icon = custom_types.image,
    tagline = types.string:length(0, 140),
    description = types.string:length(0, 2000),
    banner = custom_types.image:is_optional()
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })
  helpers.assert_error(community.organization, { 403, 'MissingPermissions' })

  local product = ProductsModel:create({
    id = uuid(),
    name = params.name,
    icon = params.icon,
    tagline = params.tagline,
    description = params.description,
    organization_id = community.id,
    banner = params.banner
  })

  return {
    status = 201,
    json = {
      id = product.id,
      name = product.name,
      icon = product.icon,
      description = product.description
    }
  }

end

return Products