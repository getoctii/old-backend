local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local ProductsModel = require 'models.products'
local PurchasesModel = require 'models.purchases'

local Purchase = {}

function Purchase:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  helpers.assert_error(product.approved, { 404, 'ProductNotFound' })

  helpers.assert_error(not PurchasesModel:find({
    user_id = self.user.id,
    product_id = product.id
  }), { 400, 'AlreadyPurchased' })

  PurchasesModel:create({
    user_id = self.user.id,
    product_id = product.id
  })

  return {
    status = 201,
    layout = false
  }
end

return Purchase