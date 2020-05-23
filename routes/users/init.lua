local helpers = require 'lapis.application'

return function(app)
  app:get('users.get.user', '/users/:id', helpers.capture_errors_json(require('routes.users.get.user')))
  app:get('users.get.members', '/users/:id/members', helpers.capture_errors_json(require('routes.users.get.members')))
  app:post('users.post.user', '/users/:id/avatar', helpers.capture_errors_json(require('routes.users.post.user')))
  app:post('users.post.login', '/users/login',  helpers.capture_errors_json(require('routes.users.post.login')))
  app:post('users.post.register', '/users',  helpers.capture_errors_json(require('routes.users.post.register')))
end