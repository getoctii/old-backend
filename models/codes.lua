local Model = require('lapis.db.model').Model

local Codes = Model:extend('codes', {
  timestamp = true
})

return Codes
