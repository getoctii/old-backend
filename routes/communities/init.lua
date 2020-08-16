local helpers = require 'lapis.application'

return function (app)
  app:post('communities.post.community', '/communities', helpers.capture_errors_json(require('routes.communities.post.community')))
  app:get('communities.get.community', '/communities/:id', helpers.capture_errors_json(require('routes.communities.get.community')))
  app:match('communitites.invites', '/communities/:id/invites', helpers.respond_to({
    GET = helpers.capture_errors_json(require('routes.communities.get.invites')),
    POST = helpers.capture_errors_json(require('routes.communities.post.invite'))
  }))
  --app:delete('communities.delete.community', '/communities/:id', helpers.capture_errors_json(require('routes.communities.delete.community')))
  app:post('communities.post.channel', '/communities/:id/channels', helpers.capture_errors_json(require('routes.communities.post.channel')))
end --owo