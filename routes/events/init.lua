local helpers = require 'lapis.application'

return function(app)
  app:get('/events/subscribe', helpers.capture_errors_json(require('routes.events.get.subscribe')))
end