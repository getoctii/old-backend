local helpers = require 'lapis.application'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local PurchasesModel = require 'models.purchases'
local array = require 'array'
local json = require 'cjson'

local Purchases = {}

function Purchases:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local purchases = array.map(PurchasesModel:select('WHERE user_id = ?', self.user.id), function(purchase)
    return purchase.product_id
  end)

  return {
    json = array.is_empty(purchases) and json.empty_array or purchases
  }
end

return Purchases