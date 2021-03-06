local helpers = require 'lapis.application'

return function(params, shape)
  return helpers.assert_error(shape:transform(params), { 400, 'InvalidParameters' })
end