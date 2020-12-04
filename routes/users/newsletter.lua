local config = require 'lapis.config'.get()
local validate = require 'lapis.validate'
local NewsletterSubscribers = require 'models.newsletter_subscriptions'
local http = require 'resty.http'
local json = require 'cjson'
local email = require 'util.email'

local Newsletter = {}

function Newsletter:POST()
  validate.assert_valid(self.params, {
    { 'email', exists = true, min_length = 3, max_length = 128, matches_regexp = email, 'InvalidEmail'}
  })

  if not NewsletterSubscribers:find({ email = self.params.email }) then
    NewsletterSubscribers:create({ email = self.params.email })
    local httpc = assert(http.new())
    assert(httpc:request_uri(config.subscriptions_webhook, {
      method = 'POST',
      headers = {
        ['content-type'] = 'application/json'
      },
      body = json.encode({
        embeds = {
          {
            title = 'New Subscriber',
            color = 5439232
          }
        },
        username = 'Octii',
        avatar_url = 'https://file.coffee/u/gpk_5iaji4.png'
      })
    }))
  end

  return {
    layout = false
  }
end

return Newsletter