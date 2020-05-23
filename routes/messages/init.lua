local helpers = require 'lapis.application'

return function(app)
  app:get('/messages/:id', helpers.capture_errors_json(require('routes.messages.get.message')))
end