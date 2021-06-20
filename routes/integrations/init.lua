local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "integrations."
app.path = "/integrations"

app:match('events', '/:id/events', guard(json_params(respond_to(require 'routes.integrations.events'))))
app:match('commands', '/:id/commands', guard(json_params(respond_to(require 'routes.integrations.commands'))))
app:match('reply', '/:id/reply', guard(json_params(respond_to(require 'routes.integrations.reply'))))

return app