local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to

local app = lapis.Application()
app.__base = app
app.name = "conversations."
app.path = "/conversations"

app:match('create', '', guard(respond_to(require 'routes.conversations.create' )))
app:match('conversation', '/:id', guard(respond_to(require 'routes.conversations.conversation' )))

return app
