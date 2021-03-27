local helpers = require 'lapis.application'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local PurchasesModel = require 'models.purchases'
local array = require 'array'
local json = require 'cjson'
local preload = require 'lapis.db.model'.preload
local VersionsModel = require 'models.versions'

local Purchases = {}

function Purchases:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local purchases = PurchasesModel:select('WHERE user_id = ?', self.user.id)
  preload(purchases, 'product')

  local mapped_purchases = array.map(PurchasesModel:select('WHERE user_id = ?', self.user.id), function(purchase)
    local product = purchase:get_product()
    local versions = VersionsModel:select('WHERE product_id = ? ORDER BY number ASC', product.id)

    return {
      id = product.id,
      name = product.name,
      icon = product.icon,
      description = product.description,
      latest_version = (versions[#versions] or {}).number
    }
  end)

  return {
    json = array.is_empty(mapped_purchases) and json.empty_array or mapped_purchases
  }
end

return Purchases