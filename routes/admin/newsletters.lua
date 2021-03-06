local NewslettersModal = require 'models.newsletter_subscriptions'
local json = require 'cjson'
local helpers = require 'lapis.application'
local empty = require 'array'.is_empty
local Newsletters = {}
local db = require 'lapis.db'
local validate = require 'util.validate'
local types = require 'tableshape'.types

function Newsletters:GET()
  local params = validate(self.params, types.shape {
    last_email_id = types.string:is_optional()
  })

  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })

  local page = params.last_email_id and
    db.query('SELECT * FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM "newsletter_subscribers" order by created_at desc) t WHERE rank > (SELECT rank FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM newsletter_subscribers) t2 WHERE email = ?) LIMIT 25', params.last_email_id)
    or NewslettersModal:select('ORDER BY created_at DESC LIMIT 25')

  if empty(page) then
    page = json.empty_array
  end

  return {
    json = page
  }
end

return Newsletters