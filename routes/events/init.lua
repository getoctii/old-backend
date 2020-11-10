local guard = require 'util.guard'

return function(app)
  app:get('/events/subscribe/:id', guard(require('routes.events.get.subscribe'))) -- TODO: innpin when?
end