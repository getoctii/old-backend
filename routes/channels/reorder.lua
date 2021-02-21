local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Channels = require 'models.channels'
local map = require 'array'.map
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local reorder_channels = require 'util.reorder_channels'
local broadcast = require 'util.broadcast'

local Reorder = {}

function Reorder:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'order', exists = true, is_array = true, 'InvalidOrder' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 2, { 400, 'ChannelNotCategory' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })
  helpers.assert_error(Set(self.params.order) == Set(map(channel:get_children(), function(row) return row.id end)), { 400, 'InvalidOrder' })

  reorder_channels(self.params.order)

  broadcast('channel:' .. channel.id, 'REORDERED_CHILDREN', {
    id = channel.id,
    order = self.params.order,
    community_id = channel.community_id,
  })

  return {
    layout = false,
    status = 204
  }
end

return Reorder