local validate = require 'util.validate'
local types = require 'tableshape'.types
local ProductsModel = require 'models.products'
local json = require 'cjson'
local array = require 'array'

local Search = {}

function Search:GET()
  local params = validate(self.params, types.shape {
    query = types.string:length(1, 16)
  })

  -- SECURITY: See thing with LIKE in other comment
  local results = array.map(ProductsModel:select("WHERE approved = TRUE AND name LIKE '%' || ? || '%' LIMIT 5", params.query), function(product)
    return product.id
  end)

  return {
    json = array.is_empty(results) and json.empty_array or results
  }
end

return Search