local model = require('lapis.db.model')
local Model = model.Model

local Versions = Model:extend('versions', {
  relations = {
    { 'product', belongs_to = 'products' }
  },
  primary_key = { 'product_id', 'number' }
})

return Versions
