local Communities = require 'models.communities'
local Members = require 'models.members'
local Users = require 'models.users'
local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local db = require 'lapis.db'
local contains = require 'array'.includes
local map = require 'array'.map
local broadcast = require 'util.broadcast'
local empty = require 'array'.is_empty
local json = require 'cjson'
local http = require 'resty.http'
local preload = require 'lapis.db.model'.preload

local Community = {}

function Community:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(contains(map(community:get_members(), function(member)
    return member.user_id
  end), self.user_id), { 403, 'MissingPermissions' })
  local channels = map(community:get_channels(), function(row)
    return row.id
  end)

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

function Community:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })
  -- TODO: NOT ATOMIC BUT OK
  local community = helpers.assert_error(Communities:find({ id = self.params.id }), 'CommunityNotFound')
  helpers.assert_error(community.owner_id == self.user_id, { 403, 'MissingPermissions' })
  preload(community, 'members')

  for _, row in ipairs(community:get_members()) do
    broadcast('user:' .. row.user_id, 'DELETED_MEMBER', {
      id = row.id
    })
  end

  assert(db.delete('communities', {
    id = self.params.id
  }))
  -- community:delete() TODO: Causes error, let's file an issue.
  assert(db.delete('members', 'community_id = ?', self.params.id))
  assert(db.delete('channels', 'community_id = ?', self.params.id))
  -- TODO: Delete messages as well.

  -- TODO: Inefficient, but /shrug

  return { layout = false }
end

function Community:PATCH()
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

return Community