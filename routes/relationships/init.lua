local guard = require 'util.guard'

return function(app)
  app:post('/relationships', guard(require('routes.relationships.post.relationship')))
  app:delete('/relationships/:id', guard(require('routes.relationships.delete.relationship')))
end