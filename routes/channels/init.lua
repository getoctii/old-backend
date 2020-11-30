local lapis = require 'lapis'
local helpers = require 'lapis.application'
local guard = require 'util.guard'

local app = lapis.Application()
app.__base = app
app.name = "channels."
app.path = "/channels"

app:match('channel', '/:id', guard(helpers.respond_to(require 'routes.channels.channel' )))
app:match('read', '/:id/read', guard(helpers.respond_to(require 'routes.channels.read' )))
app:match('messages', '/:id/messages', guard(helpers.respond_to(require 'routes.channels.messages')))
app:match('typing', '/:id/typing',guard(helpers.respond_to(require 'routes.channels.typing' )))

return app