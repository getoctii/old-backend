local CommunitiesModel = require 'models.communities'
local Members = require 'models.members'
local Users = require 'models.users'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
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
local resubscribe = require 'util.resubscribe'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Community = {}

local function sort_channels(channels)
  table.sort(channels, function(a, b)
    return a.order < b.order
  end)
end

function Community:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  local channels = community:get_channels()

  sort_channels(channels)

  channels = map(channels, function(row)
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
      base_permissions = empty(community.base_permissions) and json.empty_array or community.base_permissions,
      organization = community.organization
    }
  }
end

function Community:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  -- TODO: NOT ATOMIC BUT OK
  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), 'CommunityNotFound')
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
    id = params.id
  }))
  -- community:delete() TODO: Causes error, let's file an issue.
  assert(db.delete('members', { community_id = params.id }))
  assert(db.delete('channels', { community_id = params.id }))
  assert(db.delete('groups', { community_id = params.id }))
  assert(db.delete('invites', { community_id = params.id }))

  -- TODO: Delete associated objects.

  -- TODO: Inefficient, but /shrug

  return { layout = false }
end

function Community:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    icon = custom_types.image:is_optional(),
    name = custom_types.community_name:is_optional(),
    owner_id = custom_types.uuid:is_optional(),
    system_channel_id = custom_types.uuid:is_optional(),
    base_permissions = custom_types.permissions:is_optional(),
    organization = types.literal(true):is_optional()
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  local patch = {}

  if params.name then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })
    patch.name = params.name
  end

  if params.icon then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })
    local httpc = assert(http.new())
    local status = assert(httpc:request_uri(params.icon, { method = 'HEAD' })).status

    helpers.assert_error(status == 200, { 400, 'InvalidIcon' })
    patch.icon = params.icon
  end

  if params.owner_id then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.OWNER })), { 403, 'MissingPermissions' })
    helpers.assert_error(Users:find({ id = params.owner_id }), { 404, 'UserNotFound' })
    helpers.assert_error(Members:find({ user_id = params.owner_id, community_id = params.id }), { 404, 'UserNotFound' })
    patch.owner_id = params.owner_id
  end

  if params.organization then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.ADMINISTRATOR })), { 403, 'MissingPermissions' })
    patch.organization = params.organization
  end

  if params.system_channel_id then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })
    if params.system_channel_id ~= json.null then
      local channel = helpers.assert_error(ChannelsModel:find({ id = params.system_channel_id }), { 404, 'ChannelNotFound' })
      helpers.assert_error(channel.community_id == community.id, { 404, 'ChannelNotFound' })
      patch.system_channel_id = params.system_channel_id
    else
      patch.system_channel_id = db.NULL
    end
  end

  if params.base_permissions then
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_GROUPS })), { 403, 'MissingPermissions' })
    helpers.assert_error(engine.can_update_permissions(member, Set(community.base_permissions), params.base_permissions), { 403, 'MissingPermissions' })
    patch.base_permissions = #params.base_permissions == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.base_permissions))
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch'})
  community:update(patch)

  if params.base_permissions then
    resubscribe('community:' .. community.id)
  end

  local channels = community:get_channels()

  sort_channels(channels)

  channels = map(channels, function(row)
    return row.id
  end)

  if empty(channels) then
    channels = json.empty_array
  end

  broadcast('community:' .. community.id, 'UPDATED_COMMUNITY', {
    id = community.id,
    name = community.name,
    icon = community.icon,
    large = community.large,
    channels = channels,
    owner_id = community.owner_id,
    system_channel_id = community.system_channel_id,
    base_permissions = empty(community.base_permissions) and json.empty_array or community.base_permissions
  })

  return {
    status = 204,
    layout = false
  }
end

return Community