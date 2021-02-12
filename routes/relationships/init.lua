local lapis = require 'lapis'
local helpers = require 'lapis.application'
local guard = require 'util.guard'
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "relationships."
app.path = "/relationships"

app:match('relationship', '/:recipient_id', guard(json_params(helpers.respond_to(require 'routes.relationships.relationship' ))))

return app