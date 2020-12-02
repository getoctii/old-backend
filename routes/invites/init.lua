local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to

local app = lapis.Application()
app.__base = app
app.name = "invites."
app.path = "/invites"

app:match('invite', '/:id', guard(respond_to(require 'routes.invites.invite' )))
app:match('use', '/:code/use', guard(respond_to(require 'routes.invites.use' )))

return app