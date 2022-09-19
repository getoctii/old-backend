local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "events."
app.path = "/events"

app:match('subscribe', '/subscribe/:id', json_params(guard(respond_to(require 'routes.events.subscribe' )))) -- TODO: innpin when?

return app