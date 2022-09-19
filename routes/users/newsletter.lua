local config = require 'lapis.config'.get()
local NewsletterSubscribers = require 'models.newsletter_subscriptions'
local http = require 'resty.http'
local json = require 'cjson'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Newsletter = {}

function Newsletter:POST()
  local params = validate(self.params, types.shape {
    email = custom_types.email
  })

  if not NewsletterSubscribers:find({ email = params.email }) then
    NewsletterSubscribers:create({ email = params.email })
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
            color = 5439232,
            fields = {
              {
                name = 'Total Count',
                value = tostring(NewsletterSubscribers:count())
              }
            }
          }
        },
        username = 'Octii',
        avatar_url = 'https://file.coffee/u/Ypmv6ozGb7.jpeg'
      })
    }))
  end

  return {
    layout = false
  }
end

return Newsletter