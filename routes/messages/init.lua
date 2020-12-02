local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to

local app = lapis.Application()
app.__base = app
app.name = "messages."
app.path = "/messages"

app:match('message', '/:id', guard(respond_to(require 'routes.messages.message' )))

return app