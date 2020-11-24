local map = require 'array'.map
local helpers = require 'lapis.application'

return function(fn)
  return helpers.capture_errors(fn, function(self)
    local errors = nil

    return {
      json = self.errors
    }
  end)
end