local guard = require 'util.guard'

return function(app)
  app:get('conversations.get.conversation', '/conversations/:id', guard(require('routes.conversations.get.conversation')))
  app:post('conversations.post.conversation', '/conversations', guard(require('routes.conversations.post.conversation')))
end
