local model = require('lapis.db.model')
local Model = model.Model

local Products = Model:extend('products', {
  relations = {
    { 'organization', belongs_to = 'communities' },
    { 'resources', has_many = 'resources' }
  }
})

return Products
