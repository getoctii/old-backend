local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local helpers = require 'lapis.application'

local Communities = require 'models.communities'
local uuid = require 'util.uuid'

return function(app)
  app:post('/communities', helpers.capture_errors_json(function(self)


    local community = Communities:create({ -- TODO: handle all db errors
      id = assert(uuid()),
      name = self.params.name, -- TODO: Differenciate between query params and form
      icon = '',
      large = true
    })

    return {
      json = {
        id = community.id,
        name = community.name,
        icon = community.icon,
        large = community.large
      }
    }
  end))

  app:get('/communities/:id/channels', helpers.capture_errors_json(function(self)
  
  end))

  app:patch('/communities/:id/channels', helpers.capture_errors_json(function(self)
  
  end))
end