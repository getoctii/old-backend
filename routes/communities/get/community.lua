local Communities = require 'models.communities'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'

local json = require 'cjson'

local map = require 'util.map'
local empty = require 'util.empty'
local contains = require 'util.contains'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(contains(map(community:get_members(), function(member)
    return member.user_id
  end), self.user_id), { 403, 'MissingPermissions' })
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
      channels = channels,
      owner_id = community.owner_id
    }
  }
end