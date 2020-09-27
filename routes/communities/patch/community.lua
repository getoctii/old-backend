local Users = require 'models.users'
local Members = require 'models.members'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Community = require 'models.communities'
local empty = require 'util.empty'
local http = require 'resty.http'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'icon', exists = true, optional = true, matches_regexp = '^https:\\/\\/file\\.coffee\\/u\\/[a-zA-Z0-9_-]{7,14}\\.(png|jpeg|jpg|gif)$', 'InvalidAvatar' },
    { 'name', exists = true, optional = true, min_length = 2, max_length = 16, 'CommunityNameInvalid' },
    { 'owner_id', exists = true, optional = true, is_uuid = true, 'UUIDInvalid' }
  })

  local community = helpers.assert_error(Community:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(community.owner_id == self.user_id, { 403, 'MissingPermissions' })

  local patch = {}

  if self.params.name then
    patch.name = self.params.name
  end

  if self.params.icon then
    local httpc = assert(http.new())
    local status = assert(httpc:request_uri(self.params.icon, { method = 'HEAD' })).status

    helpers.assert_error(status == 200, { 400, 'InvalidIcon' })
    patch.icon = self.params.icon
  end

  if self.params.owner_id then
    helpers.assert_error(Users:find({ id = self.params.owner_id }), { 404, 'UserNotFound' })
    helpers.assert_error(Members:find({ user_id = self.params.owner_id, community_id = self.params.id }), { 404, 'UserNotFound' })
    patch.owner_id = self.params.owner_id
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch'})
  community:update(patch)

  return {
    status = 204,
    layout = false
  }
end
