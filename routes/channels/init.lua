local helpers = require 'lapis.application'

return function(app)
  app:match('channels.channel', '/channels/:id', helpers.respond_to({
    GET = helpers.capture_errors_json(require('routes.channels.get.channel')),
    DELETE = helpers.capture_errors_json(require('routes.channels.delete.channel'))
  }))
  -- app:get('channels.get.channel', '/channels/:id', helpers.capture_errors_json(require('routes.channels.get.channel')))
  -- app:delete('channels.delete.channel', '/channels/:id', helpers.capture_errors_json(require('routes.channels.delete.channel')))
  app:match('channels.message', '/channels/:id/messages', helpers.respond_to({
    GET = helpers.capture_errors_json(require('routes.channels.get.messages')),
    POST = helpers.capture_errors_json(require('routes.channels.post.messages'))
  }))
end
