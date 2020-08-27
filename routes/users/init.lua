local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to

return function(app)
  app:match('users.get.user', '/users/:id', respond_to({
    GET = guard(require('routes.users.get.user')),
    PATCH = guard(require('routes.users.patch.user'))
  }))
  app:get('users.get.find', '/users/find', guard(require('routes.users.get.find')))
  -- app:get('users.get.members', '/users/:id/members', guard(require('routes.users.get.members')))
  app:get('users.get.participants', '/users/:id/participants', guard(require('routes.users.get.participants')))
  -- app:post('users.post.user', '/users/:id/avatar', guard(require('routes.users.post.user')))
  app:post('users.post.login', '/users/login',  guard(require('routes.users.post.login')))
  app:post('users.post.register', '/users',  guard(require('routes.users.post.register')))
end