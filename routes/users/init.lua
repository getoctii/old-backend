local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to

local app = lapis.Application()
app.__base = app
app.name = "users."
app.path = "/users"

app:match('register', '',  guard(respond_to(require 'routes.users.register')))
app:match('code', '/code', guard(respond_to(require 'routes.users.code' )))
app:match('user', '/:id', guard(respond_to(require 'routes.users.user')))

app:match('find', '/find', guard(respond_to(require 'routes.users.find' )))
app:match('members', '/:id/members', guard(respond_to(require 'routes.users.members' )))
app:match('participants', '/:id/participants', guard(respond_to(require 'routes.users.participants' )))
app:match('login', '/login', guard(respond_to(require 'routes.users.login' )))
app:match('newsletter', '/newsletter', guard(respond_to(require 'routes.users.newsletter')))
app:match('read', '/:id/read', guard(respond_to(require 'routes.users.read' )))
app:match('mentions', '/:id/mentions', guard(respond_to(require 'routes.users.mentions')))
app:match('notifications', '/:id/notifications', guard(respond_to(require 'routes.users.notifications')))

return app