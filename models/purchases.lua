local model = require('lapis.db.model')
local Model = model.Model

local Purchases = Model:extend('purchases', {
  relations = {
    { 'user', belongs_to = 'users' },
    { 'product', belongs_to = 'products' }
  },
  primary_key = { 'user_id', 'product_id' }
})

return Purchases
