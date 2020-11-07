local guard = require 'util.guard'
local respond_to = require 'lapis.application'.respond_to
-- Uwu owo, when are we gonna replace pushpin lmao yes pushpin sucks
-- yes and feature missing or hard to understand lmao
return function(app)
  app:post('/voice', guard(require('routes.voice.post.voice')))
  app:post('/voice/:id/accept', guard(require('routes.voice.post.accept')))
  app:delete('/voice/:id', guard(require('routes.voice.delete.voice')))
end