local validate = require 'lapis.validate'

function validate.validate_functions.matches_regexp(input, check)
  -- NOTE: Case insentitive.
  return ngx.re.match(input, check, 'i'), 'InvalidInput'
end