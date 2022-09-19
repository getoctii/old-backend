local OverridesModel = require 'models.overrides'
local helpers = require 'lapis.application'
local ChannelsModel = require 'models.channels'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local db = require 'lapis.db'
local MembersModel = require 'models.members'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local broadcast = require 'util.broadcast'
local json = require 'cjson'
local resubscribe = require 'util.resubscribe'

local Overrides = {}

function Overrides:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    group_id = custom_types.uuid,
    allow = custom_types.overrides,
    deny = custom_types.overrides
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.community_id, { 404, 'ChannelNotFound' })

  local group = helpers.assert_error(GroupsModel:find({ id = params.group_id }), { 404, 'GroupNotFound' })
  helpers.assert_error(group.community_id == channel.community_id, { 404, 'GroupNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS }), channel), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.OWNER })) or (engine.get_highest_order(member) > group.order) , { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set((params.allow or Set()) + (params.deny or Set()))), { 403, 'MissingPermissions' })

  OverridesModel:create({
    channel_id = params.id,
    group_id = params.group_id,
    allow = #params.allow == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.allow)),
    deny = #params.deny == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.deny))
  })

  resubscribe('community:' .. channel.community_id)

  broadcast('channel:' .. channel.id, 'NEW_OVERRIDE', {
    channel_id = params.id,
    group_id = params.group_id,
    allow = #params.allow == 0 and json.empty_array or Set.values(params.allow),
    deny = #params.deny == 0 and json.empty_array or Set.values(params.deny)
  })

  return {
    status = 204,
    layout = false
  }
end

function Overrides:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    group_id = custom_types.uuid,
    allow = custom_types.overrides:is_optional(),
    deny = custom_types.overrides:is_optional()
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.community_id, { 404, 'ChannelNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  local group = helpers.assert_error(GroupsModel:find({ id = params.group_id }), { 404, 'GroupNotFound' })
  helpers.assert_error(group.community_id == channel.community_id, { 404, 'GroupNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS }), channel), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.OWNER })) or (engine.get_highest_order(member) > group.order) , { 403, 'MissingPermissions' })

  local override = helpers.assert_error(OverridesModel:find({
    channel_id = params.id,
    group_id = params.group_id
  }), { 404, 'OverrideNotFound' })

  if params.allow then
    helpers.assert_error(engine.can_update_permissions(member, Set(override.allow), params.allow), { 403, 'MissingPermissions' })
  end

  if params.deny then
    helpers.assert_error(engine.can_update_permissions(member, Set(override.deny), params.deny), { 403, 'MissingPermissions' })
  end

  override:update({
    allow = params.allow and (#params.allow == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.allow))) or nil,
    deny = params.deny and (#params.deny == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.deny))) or nil
  })

  resubscribe('community:' .. channel.community_id)

  broadcast('channel:' .. channel.id, 'UPDATED_OVERRIDE', {
    channel_id = params.id,
    group_id = params.group_id,
    allow = #params.allow == 0 and json.empty_array or Set.values(params.allow),
    deny = #params.deny == 0 and json.empty_array or Set.values(params.deny)
  })

  return {
    status = 204,
    layout = false
  }
end

function Overrides:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    group_id = custom_types.uuid
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.community_id, { 404, 'ChannelNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  local group = helpers.assert_error(GroupsModel:find({ id = params.group_id }), { 404, 'GroupNotFound' })
  helpers.assert_error(group.community_id == channel.community_id, { 404, 'GroupNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS }), channel), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.OWNER })) or (engine.get_highest_order(member) > group.order) , { 403, 'MissingPermissions' })

  local override = helpers.assert_error(OverridesModel:find({
    channel_id = params.id,
    group_id = params.group_id
  }), { 404, 'OverrideNotFound' })

  override:delete()

  resubscribe('community:' .. channel.community_id)

  broadcast('channel:' .. channel.id, 'DELETED_OVERRIDE', {
    channel_id = params.id,
    group_id = params.group_id
  })

  return {
    status = 200,
    layout = false
  }
end

return Overrides