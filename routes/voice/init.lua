local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "voice."
app.path = "/voice"

app:match('users', '/:id/users/:user_id', guard(json_params(respond_to(require 'routes.voice.users'))))
app:match('started', '/started/:id', guard(json_params(respond_to(require 'routes.voice.started'))))

return app