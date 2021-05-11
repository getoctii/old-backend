local validate = require 'util.validate'
local types = require 'tableshape'.types
local ProductsModel = require 'models.products'
local json = require 'cjson'
local array = require 'array'
local sanitize_sql_like = require 'util.sanitize_sql_like'

local Search = {}

function Search:GET()
  local params = validate(self.params, types.shape {
    query = types.string:length(1, 16)
  })

  local results = array.map(ProductsModel:select("WHERE approved = TRUE AND name ILIKE '%' || ? || '%' LIMIT 5", sanitize_sql_like(params.query)), function(product)
    return product.id
  end)

  return {
    json = array.is_empty(results) and json.empty_array or results
  }
end

return Search