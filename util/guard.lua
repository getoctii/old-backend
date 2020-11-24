local helpers = require 'lapis.application'
local map = require 'array'.map

return function(route)
  return helpers.capture_errors({ route, on_error = function(self)
    local status
    return {
      json = {
        errors = map(self.errors, function(error)
          if type(error) == 'string' then
			      status = 400
			      return error
		      elseif type(error) == 'table' then
			      status = error[1]
			      return error[2]
		      end
		    end)
	    },
	    status = status
	  }
  end})
end