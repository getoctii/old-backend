local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "voice."
app.path = "/voice"

app:match('voice', '', guard(json_params(respond_to(require 'routes.voice.voice'))))
app:match('accept', '/:id/accept', guard(json_params(respond_to(require 'routes.voice.accept'))))

return app