local lapis = require 'lapis'
local helpers = require 'lapis.application'
local guard = require 'util.guard'
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "admin."
app.path = "/admin"

app:match('codes', '/codes', guard(json_params(helpers.respond_to(require 'routes.admin.codes' ))))
app:delete('delete_code', '/codes/:id', guard(json_params(helpers.respond_to(require 'routes.admin.codes'))))
app:match('newsletters', '/newsletters', guard(json_params(helpers.respond_to(require 'routes.admin.newsletters'))))
app:match('users', '/users/:id', guard(json_params(helpers.respond_to(require 'routes.admin.users'))))

return app