local NewsletterSubscribers = require 'models.newsletter_subscriptions'
local json = require 'cjson'
local contains = require 'array'.includes
local helpers = require 'lapis.application'
local empty = require 'array'.is_empty
local Newsletters = {}
local Users = require 'models.users'

function Newsletters:GET()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })
  
  local pager = NewsletterSubscribers:paginated('order by created_at desc', {
    per_page = 25
  })

  local page = pager:get_page(self.params.created_at)

  if empty(page) then
    page = json.empty_array
  end

  return {
    json = page
  }
end

return Newsletters