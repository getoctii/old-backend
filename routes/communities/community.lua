local CommunitiesModel = require 'models.communities'
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
local ChannelsModel = require 'models.channels'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local GroupsModel = require 'models.groups'
local Set = require 'pl.Set'
local C = require 'pl.comprehension'.new()
local Community = {}

local permission_set = Set(C 'x for x=1,17' ())

function Community:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
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
      owner_id = community.owner_id,
      system_channel_id = community.system_channel_id,
      base_permissions = empty(community.base_permissions) and json.empty_array or community.base_permissions
    }
  }
end

function Community:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })
  -- TODO: NOT ATOMIC BUT OK
  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), 'CommunityNotFound')
  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.OWNER })), { 403, 'MissingPermissions' })

  preload(community, 'members')

  for _, row in ipairs(community:get_members()) do
    broadcast('user:' .. row.user_id, 'DELETED_MEMBER', {
      id = row.id,
      community_id = community.id
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
    { 'owner_id', exists = true, optional = true, is_uuid = true, 'InvalidOwnerUUID' },
    { 'system_channel_id', exists = true, optional = true, 'InvalidChannelUUID'},
    { 'base_permissions', exists = true, optional = true, 'InvalidPermissions' }
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  local patch = {}

  if self.params.name then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })
    patch.name = self.params.name
  end

  if self.params.icon then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })
    local httpc = assert(http.new())
    local status = assert(httpc:request_uri(self.params.icon, { method = 'HEAD' })).status

    helpers.assert_error(status == 200, { 400, 'InvalidIcon' })
    patch.icon = self.params.icon
  end

  if self.params.owner_id then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.OWNER })), { 403, 'MissingPermissions' })
    helpers.assert_error(Users:find({ id = self.params.owner_id }), { 404, 'UserNotFound' })
    helpers.assert_error(Members:find({ user_id = self.params.owner_id, community_id = self.params.id }), { 404, 'UserNotFound' })
    patch.owner_id = self.params.owner_id
  end

  if self.params.system_channel_id then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })
    if self.params.system_channel_id ~= json.null then
      local channel = helpers.assert_error(ChannelsModel:find({ id = self.params.system_channel_id }), { 404, 'ChannelNotFound' })
      helpers.assert_error(channel.community_id == community.id, { 404, 'ChannelNotFound' })
      patch.system_channel_id = self.params.system_channel_id
    else
      patch.system_channel_id = db.NULL
    end
  end

  if self.params.base_permissions then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PERMISSIONS })), { 403, 'MissingPermissions' })
    helpers.assert_error(engine.can_update_permissions(member, Set(community.base_permissions), Set(self.params.base_permissions)), { 403, 'MissingPermissions' })
    helpers.assert_error(type((self.params.base_permissions) == 'table') and ((Set(self.params.base_permissions) + permission_set) == permission_set), { 400, 'InvalidPermissions' })
    patch.base_permissions = empty(self.params.permissions) and db.raw('array[]::integer[]') or db.array(Set.values(Set(self.params.base_permissions)))
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch'})
  community:update(patch)

  return {
    status = 204,
    layout = false
  }
end

return Community