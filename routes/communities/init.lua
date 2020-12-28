local lapis = require 'lapis'
local helpers = require 'lapis.application'
local guard = require 'util.guard'

local app = lapis.Application()
app.__base = app
app.name = "communities."
app.path = "/communities"

app:match('create', '', guard(helpers.respond_to(require 'routes.communities.create')))
app:match('community', '/:id', guard(helpers.respond_to(require 'routes.communities.community')))
app:match('invites', '/:id/invites', guard(helpers.respond_to(require 'routes.communities.invites')))
app:match('channels', '/:id/channels', guard(helpers.respond_to(require 'routes.communities.channels')))
app:match('leave', '/:id/leave', guard(helpers.respond_to(require 'routes.communities.leave')))
app:match('members', '/:id/members', guard(helpers.respond_to(require 'routes.communities.members')))
app:match('members_search', '/:id/members/search', guard(helpers.respond_to(require 'routes.communities.members_search')))


return app