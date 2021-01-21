local NewsletterSubscribers = require 'models.newsletter_subscriptions'
local json = require 'cjson'
local helpers = require 'lapis.application'
local empty = require 'array'.is_empty
local Newsletters = {}
local OrderedPaginator = require 'lapis.db.pagination'.OrderedPaginator

function Newsletters:GET()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })
  
  local pager = OrderedPaginator(NewsletterSubscribers, 'created_at', {
    per_page = 25,
    order = 'asc'
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