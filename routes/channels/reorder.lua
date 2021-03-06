local helpers = require 'lapis.application'
local Channels = require 'models.channels'
local map = require 'array'.map
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local reorder_channels = require 'util.reorder_channels'
local broadcast = require 'util.broadcast'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Reorder = {}

function Reorder:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    order = types.array_of(types.number)
  })

  local channel = helpers.assert_error(Channels:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 2, { 400, 'ChannelNotCategory' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })
  helpers.assert_error(Set(params.order) == Set(map(channel:get_children(), function(row) return row.id end)), { 400, 'InvalidOrder' })

  reorder_channels(params.order)

  broadcast('channel:' .. channel.id, 'REORDERED_CHILDREN', {
    id = channel.id,
    order = params.order,
    community_id = channel.community_id,
  })

  return {
    layout = false,
    status = 204
  }
end

return Reorder