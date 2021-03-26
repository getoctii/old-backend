local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local ProductsModel = require 'models.products'
local VersionsModel = require 'models.versions'

local Version = {}

function Version:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    version_id = types.integer + (types.string / tonumber * types.integer)
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  local version = helpers.assert_error(VersionsModel:find({ product_id = product.id, number = params.version_id }), { 404, 'VersionNotfound' })

  return {
    json = {
      name = version.name,
      description = version.description,
      number = version.number
    }
  }
end

return Version