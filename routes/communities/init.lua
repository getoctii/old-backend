local helpers = require 'lapis.application'
local guard = require 'util.guard'

return function (app)
  app:post('communities.post.community', '/communities', guard(require('routes.communities.post.community')))
  app:get('communities.get.community', '/communities/:id', guard(require('routes.communities.get.community')))
  app:match('communitites.invites', '/communities/:id/invites', helpers.respond_to({
    GET = guard(require('routes.communities.get.invites')),
    POST = guard(require('routes.communities.post.invite'))
  }))
  --app:delete('communities.delete.community', '/communities/:id', helpers.capture_errors_json(require('routes.communities.delete.community')))
  app:post('communities.post.channel', '/communities/:id/channels', guard(require('routes.communities.post.channel')))
end --owo