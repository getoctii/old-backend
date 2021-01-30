local lapis = require 'lapis'
local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "members."
app.path = "/members"

app:match('groups', '/:id/:group_id', guard(json_params(respond_to(require 'routes.members.groups' ))))
app:match('member', '/:id', guard(json_params(respond_to(require 'routes.members.member'))))

return app