local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to

local app = lapis.Application()
app.__base = app
app.name = "events."
app.path = "/events"

app:match('subscribe', '/subscribe/:id', guard(respond_to(require 'routes.events.subscribe' ))) -- TODO: innpin when?

return app