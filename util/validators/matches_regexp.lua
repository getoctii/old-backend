local validate = require 'lapis.validate'

function validate.validate_functions.matches_regexp(input, check)
  return ngx.re.match(input, check), 'InvalidInput'
end