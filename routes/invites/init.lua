return function(app)
  app:get('invites.get.invite', '/invites/:id', require('routes.invites.get.invite'))
  app:post('invites.post.invite', '/invites/:id/use', require('routes.invites.post.use'))
end