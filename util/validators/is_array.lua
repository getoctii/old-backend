local validate = require 'lapis.validate'
local array = require 'array'
function validate.validate_functions.is_array(input, check)
  if check then
    return array.is_array(input), 'InvalidType'
  end

  return true
end