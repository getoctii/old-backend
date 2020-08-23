local Communities = require 'models.communities'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'

local json = require 'cjson'

local map = require 'util.map'
local empty = require 'util.empty'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' } }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  local invites = map(community:get_invites(), function(row)
    return {
      id = row.id,
      code = row.code,
      author_id = row.author_id,
      created_at = row.created_at,
      updated_at = row.updated_at,
      uses = row.uses
    }
  end)

  if empty(invites) then
    invites = json.empty_array
  end

  return {
    json = invites
  }
end