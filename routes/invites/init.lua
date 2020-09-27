local guard = require 'util.guard'

return function(app)
  app:delete('invites.delete.invite', '/invites/:id', guard(require('routes.invites.delete.invite')))
  app:post('invites.post.invite', '/invites/:code/use', guard(require('routes.invites.post.use')))
end