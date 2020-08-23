local Communities = require 'models.communities'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'

local json = require 'cjson'

local map = require 'util.map'
local empty = require 'util.empty'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' }}
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  local channels = map(community:get_channels(), function(row) return {name = row.name, id = row.id} end)

  if empty(channels) then
    channels = json.empty_array
  end

  return {
    json = {
      id = community.id,
      name = community.name,
      icon = community.icon,
      large = community.large,
      channels = channels
    }
  }
end