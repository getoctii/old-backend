local ChannelsModel = require 'models.channels'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
local contains = require 'array'.includes
local map = require 'array'.map
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local empty = require 'array'.is_empty
local Read = require 'models.read'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local json = require 'cjson'
local reorder_channels = require 'util.reorder_channels'
local array = require 'array'

local Channel = {}

function Channel:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = self.params.id }), { 404, 'ChannelNotFound' })
  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES })), { 403, 'MissingPermissions' })
  end

  local read = Read:find({ user_id = self.user.id, channel_id = channel.id })
  local pager = channel:get_messages_paginated({
    per_page = 1,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  return {
    json = {
      id = channel.id,
      name = channel.name,
      community_id = channel.community_id,
      description = channel.description,
      color = channel.color,
      read = (read or {}).last_read_id,
      last_message_id = (pager:get_page()[1] or {}).id,
      order = channel.order,
      type = channel.type,
      parent_id = channel.parent_id
    }
  }
end

-- TODO: Handle edge case where user tries to delete DM channel.
function Channel:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = self.params.id }), 'ChannelNotFound')
  if not channel.community_id then
    helpers.yield_error({ 400, 'InvalidChannel' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })
  end

  assert(db.delete('channels', {
    id = channel.id
  }))
  assert(db.delete('messages', 'channel_id = ?', self.params.id))

  broadcast('community:' .. channel.community_id, 'DELETED_CHANNEL', {
    id = channel.id,
    community_id = channel.community_id
  })

  resubscribe('community:' .. channel.community_id)

  return {
    layout = false
  }
end

function Channel:PATCH()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'name', exists = true, optional = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, 'ChannelNameInvalid' },
    { 'description', exists = true, optional = true, max_length = 140, 'InvalidDescription' },
    { 'color', exists = true, optional = true, is_color = true, 'InvalidColor' },
    { 'parent', exists = true, optional = true, is_uuid = true, 'InvalidParentUUID' },
    { 'parent_order', exists = true, optional = true, is_array = true, 'InvalidParentUUID' }
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = self.params.id }), { 404, 'ChannelNotFound' })
  if not channel.community_id then
    helpers.yield_error({ 400, 'InvalidChannel' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })), { 403, 'MissingPermissions' })
  end

  local patch = {}

  if self.params.name then
    patch.name = self.params.name
  end

  if self.params.description and channel.type == 1 then
    patch.description = self.params.description
  end

  if self.params.color and channel.type == 1  then
    patch.color = self.params.color
  end

  if self.params.parent then
    helpers.assert_error(channel.type == 1 and channel.community_id, { 400, 'InvalidChannel' })
    helpers.assert_error(self.params.parent_order, { 400, 'InvalidParentOrder' })

    if self.params.parent == json.null then
      helpers.assert_error(Set(self.params.order) == (Set(map(array.filter(channel:get_community():get_channels(), function(row)
        return not row.parent_id
      end), function(row)
        return row.id
      end)) + Set({ channel.id })), { 400, 'InvalidParentOrder' })

      if channel.parent_id then
        local children = map(channel:get_parent():get_children(), function(row) return row.id end)
        reorder_channels(array.without(children, channel.id))
      end

      reorder_channels(self.params.parent_order)

      patch.parent_id = db.NULL
    else
      local parent = helpers.assert_error(ChannelsModel:find({ id = self.params.parent }), { 404, 'CategoryNotFound' })
      helpers.assert_error(parent.community_id == channel.community_id and parent.type == ChannelsModel.types.CATEGORY, { 400, 'InvalidParent'} )
      helpers.assert_error(Set(self.params.parent_order) == (Set(map(parent:get_children(), function(row) return row.id end)) + Set({ channel.id })), { 400, 'InvalidParentOrder' })

      if channel.parent_id then
        local children = map(channel:get_parent():get_children(), function(row) return row.id end)
        reorder_channels(array.without(children, channel.id))
      else
        local children = map(array.filter(channel:get_community():get_channels(), function(row)
          return not row.parent_id
        end), function(row) return row.id end)
        reorder_channels(array.without(children, channel.id))
      end

      reorder_channels(self.params.parent_order)

      patch.parent_id = self.params.parent
    end
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch' })
  channel:update(patch)

  return {
    status = 204,
    layout = false
  }
end

return Channel