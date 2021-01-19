local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "invites."
app.path = "/invites"

app:match('invite', '/:id', guard(json_params(respond_to(require 'routes.invites.invite' ))))
app:match('use', '/:code/use', guard(json_params(respond_to(require 'routes.invites.use' ))))

return app