local Users = require 'models.users'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'

local json = require 'cjson'
local empty = require 'array'.is_empty

local Mentions = {}

function Mentions:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.params.id == self.user_id, { 403, 'InvalidUser' })

  local mentions = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' }):get_mentions()

  return {
    json = empty(mentions) and json.empty_array or mentions
  }
end

return Mentions