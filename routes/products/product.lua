local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local ProductsModel = require 'models.products'
local MembersModel = require 'models.members'
local PurchasesModel = require 'models.purchases'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

local Product = {}

function Product:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  helpers.assert_error(product.approved or engine.has_community_permissions(helpers.assert_error(MembersModel:find({
    community_id = product.organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' }), Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  return {
    json = {
      id = product.id,
      name = product.name,
      icon = product.icon,
      description = product.description,
      tagline = product.tagline,
      banner = product.banner,
      purchases = #PurchasesModel:select('WHERE product_id = ?', product.id)
    }
  }
end

function Product:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.community_name:is_optional(),
    icon = custom_types.image:is_optional(),
    tagline = types.string:length(0, 140):is_optional(),
    description = types.string:length(0, 2000):is_optional(),
    banner = custom_types.image:is_optional()
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = product.organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  product:update({
    name = params.name,
    icon = params.icon,
    tagline = params.tagline,
    description = params.description,
    banner = params.banner
  })

  return {
    status = 200,
    layout = false
  }
end

-- function Product:DELETE()
-- end

return Product