local validate = require 'lapis.validate'
local NewsletterSubscribers = require 'models.newsletter_subscriptions'

return function(self)
  validate.assert_valid(self.params, {
    { 'email', exists = true, min_length = 3, max_length = 128, matches_pattern = '^[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?$', { 400, 'InvalidEmail' }}
  })

  if not NewsletterSubscribers:find({ email = self.params.email }) then
    NewsletterSubscribers:create({ email = self.params.email })
  end

  return {
    layout = false
  }
end
