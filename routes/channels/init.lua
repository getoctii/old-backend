local lapis = require 'lapis'
local helpers = require 'lapis.application'
local guard = require 'util.guard'
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "channels."
app.path = "/channels"

app:match('channel', '/:id', guard(json_params(helpers.respond_to(require 'routes.channels.channel' ))))
app:match('read', '/:id/read', guard(json_params(helpers.respond_to(require 'routes.channels.read' ))))
app:match('messages', '/:id/messages', guard(json_params(helpers.respond_to(require 'routes.channels.messages'))))
app:match('typing', '/:id/typing',guard(json_params(helpers.respond_to(require 'routes.channels.typing' ))))
app:match('overrides', '/:id/overrides/:group_id', guard(json_params(helpers.respond_to(require 'routes.channels.overrides'))))
app:match('join', '/:id/join', guard(json_params(helpers.respond_to(require 'routes.channels.join'))))
app:match('webhook', '/:id/webhook/:code', guard(json_params(helpers.respond_to(require 'routes.channels.webhook'))))
app:match('execute', '/:id/execute', guard(json_params(helpers.respond_to(require 'routes.channels.execute'))))

return app