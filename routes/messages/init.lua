local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "messages."
app.path = "/messages"

app:match('message', '/:id', guard(json_params(respond_to(require 'routes.messages.message' ))))

return app