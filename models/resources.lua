local model = require('lapis.db.model')
local Model, enum = model.Model, model.enum

local Resources = Model:extend('resources', {
  relations = {
    { 'product', belongs_to = 'products' }
  }
})

Resources.types = enum {
  THEME = 1,
  CLIENT_INTEGRATION = 2,
  SERVER_INTEGRATION = 3
}

return Resources
