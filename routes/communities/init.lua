local lapis = require 'lapis'
local helpers = require 'lapis.application'
local guard = require 'util.guard'
local json_params = require 'lapis.application'.json_params

local app = lapis.Application()
app.__base = app
app.name = "communities."
app.path = "/communities"

app:match('create', '', guard(json_params(helpers.respond_to(require 'routes.communities.create'))))
app:match('community', '/:id', guard(json_params(helpers.respond_to(require 'routes.communities.community'))))
app:match('invites', '/:id/invites', guard(json_params(helpers.respond_to(require 'routes.communities.invites'))))
app:match('channels', '/:id/channels', guard(json_params(helpers.respond_to(require 'routes.communities.channels'))))
app:match('leave', '/:id/leave', guard(json_params(helpers.respond_to(require 'routes.communities.leave'))))
app:match('members', '/:id/members', guard(json_params(helpers.respond_to(require 'routes.communities.members'))))
app:match('members_info', '/:id/members/:user_id', guard(json_params(helpers.respond_to(require 'routes.communities.members_info'))))
app:match('members_search', '/:id/members/search', guard(json_params(helpers.respond_to(require 'routes.communities.members_search'))))
app:match('groups', '/:id/groups', guard(json_params(helpers.respond_to(require 'routes.communities.groups'))))
app:match('products', '/:id/products', guard(json_params(helpers.respond_to(require 'routes.communities.products'))))
app:match('integrations', '/:id/integrations', guard(json_params(helpers.respond_to(require 'routes.communities.integrations'))))

return app