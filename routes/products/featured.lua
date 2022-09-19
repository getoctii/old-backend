local db = require 'lapis.db'
local array = require 'array'
local json = require 'cjson'

local Featured = {}

function Featured:GET()
  local top = db.query('SELECT * FROM (SELECT products.id, COUNT(products.id) FROM products INNER JOIN purchases p on products.id = p.product_id AND products.approved = true GROUP BY products.id LIMIT 20) AS pr INNER JOIN products ON pr.id = products.id ORDER BY pr.count DESC')
  local results = array.map(top, function(product)
    return {
      id = product.id,
      name = product.name,
      icon = product.icon,
      description = product.description,
      tagline = product.tagline,
      banner = product.banner
    }
  end)

  return {
    json = array.is_empty(results) and json.empty_array or results
  }
end

return Featured