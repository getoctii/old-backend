local validate = require 'lapis.validate'
local CommunitiesModel = require 'models.communities'
local helpers = require 'lapis.application'
local ChannelsModel = require 'models.channels'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'

local Channels = {}

local function sort_channels(channels)
  table.sort(channels, function(a, b)
    return a.order < b.order
  end)
end

local function reorder_channels(order)
  for i, v in ipairs(order) do
    local channel = ChannelsModel:find({ id = v })
    channel:update({
      order = i
    })
  end
end

function Channels:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })
  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES })), { 403, 'MissingPermissions' })

  local channels = map(community:get_channels(), function(row)
    return {
      id = row.id,
      name = row.name,
      description = row.description,
      color = row.color,
      order = row.order,
      type = row.type
    }
  end)

  sort_channels(channels)

  if empty(channels) then
    channels = json.empty_array
  end

  return {
    json = channels
  }
end

function Channels:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'},
    { 'name', exists = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, 'ChannelNameInvalid'},
    { 'type', exists = true, optional = true }
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })

  local channel = ChannelsModel:create({
    id = uuid(),
    name = self.params.name,
    community_id = community.id,
    type = self.params.type and self.params.type or 1
  })

  broadcast('community:' .. community.id, 'NEW_CHANNEL', {
    id = channel.id,
    name = channel.name, -- SECURITY: REMOVE NAME, AT LEAST FOR THOSE WHO DON'T HAVE PERMS
    community_id = channel.community_id,
    type = channel.type
  })

  resubscribe('community:' .. community.id)

  return {
    json = {
      id = channel.id,
      name = channel.name,
      type = channel.type
    }
  }
end

function Channels:PATCH()
  validate.assert_valid(self.params, {
    { 'order', exists = true, optional = true, is_array = true, 'InvalidOrder' }
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })

  if self.params.order then
    helpers.assert_error(Set(self.params.order) == Set(map(community:get_channels(), function(row) return row.id end)), { 400, 'InvalidOrder' })

    reorder_channels(self.params.order)

    broadcast('community:' .. community.id, 'REORDERED_CHANNELS', {
      community_id = community.id,
      order = self.params.order
    })
  end

  return {
    status = 204,
    layout = false
  }
end

return Channels