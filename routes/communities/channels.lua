local CommunitiesModel = require 'models.communities'
local helpers = require 'lapis.application'
local ChannelsModel = require 'models.channels'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local array = require 'array'
local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

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
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES })), { 403, 'MissingPermissions' })
  local raw_channels = community:get_channels()

  local channels = map(array.filter(raw_channels, function(row)
    return engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES }), row)
  end), function(row)
    return {
      id = row.id,
      name = row.name,
      description = row.description,
      color = row.color,
      order = row.order,
      type = row.type,
      parent_id = row.parent_id
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
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.channel_name,
    type = types.one_of {
      ChannelsModel.types.TEXT,
      ChannelsModel.types.CATEGORY,
      ChannelsModel.types.VOICE,
      ChannelsModel.types.CUSTOM
    }
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })

 local channel_ids = map(array.filter(community:get_channels(), function(row)
    return not row.parent_id
  end), function(row)
    return row.id
  end)

  local channel = ChannelsModel:create({
    id = uuid(),
    name = params.name,
    community_id = community.id,
    type = params.type and params.type or 1
  })

  reorder_channels(array.concat({ channel.id }, channel_ids))

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
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    order = types.array_of(types.number)
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })

  if params.order then
    helpers.assert_error(Set(params.order) == Set(map(array.filter(community:get_channels(), function(row)
      return not row.parent_id
    end), function(row)
      return row.id
    end)), { 400, 'InvalidOrder' })

    reorder_channels(params.order)

    broadcast('community:' .. community.id, 'REORDERED_CHANNELS', {
      community_id = community.id,
      order = params.order
    })
  end

  return {
    status = 204,
    layout = false
  }
end

return Channels