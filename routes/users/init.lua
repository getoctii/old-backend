local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "users."
app.path = "/users"

app:match('register', '',  guard(json_params(respond_to(require 'routes.users.register'))))
app:match('user', '/:id', guard(json_params(respond_to(require 'routes.users.user'))))
app:match('find', '/find', guard(json_params(respond_to(require 'routes.users.find' ))))
app:match('members', '/:id/members', guard(json_params(respond_to(require 'routes.users.members' ))))
app:match('participants', '/:id/participants', guard(json_params(respond_to(require 'routes.users.participants' ))))
app:match('login', '/login', guard(json_params(respond_to(require 'routes.users.login' ))))
app:match('newsletter', '/newsletter', guard(json_params(respond_to(require 'routes.users.newsletter'))))
app:match('read', '/:id/read', guard(json_params(respond_to(require 'routes.users.read' ))))
app:match('mentions', '/:id/mentions', guard(json_params(respond_to(require 'routes.users.mentions'))))
app:match('notifications', '/:id/notifications', guard(json_params(respond_to(require 'routes.users.notifications'))))
app:match('relationships', '/:id/relationships', guard(json_params(respond_to(require 'routes.users.relationships'))))
app:match('purchases', '/:id/purchases', guard(json_params(respond_to(require 'routes.users.purchases'))))
app:match('organizations', '/:id/organizations', guard(json_params(respond_to(require 'routes.users.organizations'))))
app:match('keychain', '/:id/keychain', guard(json_params(respond_to(require 'routes.users.keychain'))))
app:match('totp', '/:id/totp', guard(json_params(respond_to(require 'routes.users.totp'))))

return app