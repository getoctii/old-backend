local Model = require('lapis.db.model').Model

local NewsletterSubscribers = Model:extend('newsletter_subscribers', {
  timestamp = true,
  primary_key = 'email'
})

return NewsletterSubscribers
