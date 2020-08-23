local guard = require 'util.guard'

return function(app)
  app:get('users.get.user', '/users/:id', guard(require('routes.users.get.user')))
  app:get('users.get.find', '/users/find', guard(require('routes.users.get.find')))
  app:get('users.get.members', '/users/:id/members', guard(require('routes.users.get.members')))
  app:get('users.get.participants', '/users/:id/participants', guard(require('routes.users.get.participants')))
  app:post('users.post.user', '/users/:id/avatar', guard(require('routes.users.post.user')))
  app:post('users.post.login', '/users/login',  guard(require('routes.users.post.login')))
  app:post('users.post.register', '/users',  guard(require('routes.users.post.register')))
end