local guard = require 'util.guard'

return function(app)
  app:get('/events/subscribe', guard(require('routes.events.get.subscribe')))
end