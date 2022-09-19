local validate = require 'lapis.validate'
local uuid = require 'resty.jit-uuid' -- NOTE: Only use for uuid validation, we have our own library for generating which uses openssl.

function validate.validate_functions.is_uuid(input, check)
  if check then
    return uuid.is_valid(input), 'InvalidUUID'
  end

  return true
end