local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to

return function(app)
  app:post('conversations.post.conversation', '/conversations', guard(require('routes.conversations.post.conversation')))
  app:match('conversations.get.conversation', '/conversations/:id', respond_to({
    GET = guard(require('routes.conversations.get.conversation')),
    DELETE = guard(require('routes.conversations.delete.conversation'))
  }))
end
