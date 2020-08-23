local guard = require 'util.guard'

return function(app)
  app:get('/messages/:id', guard(require('routes.messages.get.message')))
end