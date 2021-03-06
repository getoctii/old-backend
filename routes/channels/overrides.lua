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
  helpers.assert_error(group.community_id == channel.community_id)

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })))

  OverridesModel:create({
    channel_id = params.id,
    group_id = params.group_id,
    allow = #params.allow == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.allow)),
    deny = #self.params.deny == 0 and db.raw('array[]::integer[]') or db.array(Set.values(self.params.deny))
  })

  return {
    status = 204,
    layout = false
  }
end

function Overrides:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    allow = custom_types.overrides:is_optional(),
    deny = custom_types.overrides:is_optional()
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.community_id, { 404, 'ChannelNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })))

  local override = helpers.assert_error(OverridesModel:find({
    channel_id = params.id,
    group_id = params.group_id
  }), { 404, 'OverrideNotFound' })

  override:update({
    allow = params.allow and (#params.allow == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.allow))) or nil,
    deny = params.deny and (#params.deny == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.deny))) or nil
  })

  return {
    status = 204,
    layout = false
  }
end

return Overrides