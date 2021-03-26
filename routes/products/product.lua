local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local ProductsModel = require 'models.products'

local Product = {}

function Product:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })

  return {
    json = {
      id = product.id,
      name = product.name,
      icon = product.icon,
      description = product.description
    }
  }
end

function Product:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.community_name:is_optional(),
    icon = custom_types.image:is_optional(),
    description = types.string:length(0, 140):is_optional()
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })

  product:update({
    name = params.name,
    icon = params.icon,
    description = params.description
  })

  return {
    status = 200,
    layout = false
  }
end

function Product:DELETE()
end

return Product