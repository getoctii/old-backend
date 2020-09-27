local helpers = require 'lapis.application'
local guard = require 'util.guard'

return function(app)
  app:match('channels.channel', '/channels/:id', helpers.respond_to({
    DELETE = guard(require('routes.channels.delete.channel')),
    PATCH = guard(require('routes.channels.patch.channel'))
  }))
  -- app:get('channels.get.channel', '/channels/:id', helpers.capture_errors_json(require('routes.channels.get.channel')))
  -- app:delete('channels.delete.channel', '/channels/:id', helpers.capture_errors_json(require('routes.channels.delete.channel')))
  app:match('channels.message', '/channels/:id/messages', helpers.respond_to({
    GET = guard(require('routes.channels.get.messages')),
    POST = guard(require('routes.channels.post.messages'))
  }))

  -- app:post('channels.typing', '/channels/:id/typing', guard(require('routes.channels.post.typing')))
end
