local ChannelsModel = require 'models.channels'
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
local OverridesModel = require 'models.overrides'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Channel = {}

function Channel:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES }), channel), { 403, 'MissingPermissions' })
  end

  local read = Read:find({ user_id = self.user.id, channel_id = channel.id })
  local pager = channel:get_messages_paginated({
    per_page = 1,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  local overrides = OverridesModel:select('WHERE channel_id = ?', channel.id)
  local mapped_overrides = {}

  if overrides ~= nil then
    for _, override in ipairs(overrides) do
      mapped_overrides[override.group_id] = {
        allow = empty(override.allow) and json.empty_array or override.allow,
        deny = empty(override.deny) and json.empty_array or override.deny
      }
    end
  end

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
      parent_id = channel.parent_id,
      overrides = mapped_overrides,
      base_allow = channel.base_allow,
      base_deny = channel.base_deny
    }
  }
end

function Channel:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), 'ChannelNotFound')
  if not channel.community_id then
    helpers.yield_error({ 400, 'InvalidChannel' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS }), channel), { 403, 'MissingPermissions' })
  end

  if channel.parent_id then
    local children = map(channel:get_parent():get_children(), function(row) return row.id end)
    reorder_channels(array.without(children, { channel.id }))
  else
    if channel.type == ChannelsModel.types.CATEGORY then
      db.update('channels', {
        parent_id = db.NULL
      }, 'parent_id = ?', channel.parent_id)
    end

    local children = map(array.filter(channel:get_community():get_channels(), function(row)
      return not row.parent_id
    end), function(row) return row.id end)
    reorder_channels(array.without(children, { channel.id }))
  end

  channel:delete()
  assert(db.delete('messages', 'channel_id = ?', params.id))

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
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.channel_name:is_optional(),
    description = types.string:length(0, 140):is_optional(),
    color = custom_types.color:is_optional(),
    parent = custom_types.uuid:is_optional(),
    parent_order = types.number:is_optional(),
    base_allow = custom_types.overrides:is_optional(),
    base_deny = custom_types.overrides:is_optional()
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  if not channel.community_id then
    helpers.yield_error({ 400, 'InvalidChannel' })
  end

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS }), channel), { 403, 'MissingPermissions' })

  local patch = {}

  if params.name then
    patch.name = params.name
  end

  if params.description and channel.type == 1 then
    patch.description = params.description
  end

  if params.color and channel.type == 1  then
    patch.color = params.color
  end

  if params.base_allow then
    helpers.assert_error(engine.can_update_permissions(member, Set(channel.base_allow), params.base_allow), { 403, 'MissingPermissions' })
    patch.base_allow = #params.base_allow == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.base_allow))
  end

  if params.base_deny then
    helpers.assert_error(engine.can_update_permissions(member, Set(channel.base_deny), params.base_deny), { 403, 'MissingPermissions' })
    patch.base_deny = #params.base_deny == 0 and db.raw('array[]::integer[]') or db.array(Set.values(params.base_deny))
  end

  if params.parent then
    helpers.assert_error(channel.type == 1 and channel.community_id, { 400, 'InvalidChannel' })
    helpers.assert_error(params.parent_order, { 400, 'InvalidParentOrder' })

    if params.parent == json.null then
      helpers.assert_error(Set(params.parent_order) == (Set(map(array.filter(channel:get_community():get_channels(), function(row)
        return not row.parent_id
      end), function(row)
        return row.id
      end)) + Set({ channel.id })), { 400, 'InvalidParentOrder' })

      if channel.parent_id then
        local children = map(channel:get_parent():get_children(), function(row) return row.id end)
        reorder_channels(array.without(children, { channel.id }))
        broadcast('channel:' .. channel.parent_id, 'REORDERED_CHILDREN', {
          id = channel.parent_id,
          order = array.without(children, { channel.id }),
          community_id = channel.community_id,
        })
      end

      reorder_channels(params.parent_order)
      broadcast('community:' .. channel.community_id, 'REORDERED_CHANNELS', {
        community_id = channel.community_id,
        order = params.parent_order,
      })

      patch.parent_id = db.NULL
    else
      local parent = helpers.assert_error(ChannelsModel:find({ id = params.parent }), { 404, 'CategoryNotFound' })
      helpers.assert_error(parent.community_id == channel.community_id and parent.type == ChannelsModel.types.CATEGORY, { 400, 'InvalidParent'} )
      helpers.assert_error(Set(params.parent_order) == (Set(map(parent:get_children(), function(row) return row.id end)) + Set({ channel.id })), { 400, 'InvalidParentOrder' })

      if channel.parent_id then
        local children = map(channel:get_parent():get_children(), function(row) return row.id end)
        reorder_channels(array.without(children, { channel.id }))
        broadcast('channel:' .. channel.parent_id, 'REORDERED_CHILDREN', {
          id = channel.parent_id,
          order = array.without(children, { channel.id }),
          community_id = channel.community_id,
        })
      else
        local children = map(array.filter(channel:get_community():get_channels(), function(row)
          return not row.parent_id
        end), function(row) return row.id end)
        reorder_channels(array.without(children, { channel.id }))
        broadcast('community:' .. channel.community_id, 'REORDERED_CHANNELS', {
          community_id = channel.community_id,
          order = array.without(children, { channel.id }),
        })
      end

      reorder_channels(params.parent_order)
      broadcast('channel:' .. params.parent, 'REORDERED_CHILDREN', {
        id = params.parent,
        order = params.parent_order,
        community_id = channel.community_id,
      })

      patch.parent_id = params.parent
    end
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch' })
  channel:update(patch)

  broadcast('channel:' .. channel.id, 'UPDATED_CHANNEL', {
    id = channel.id,
    name = channel.name,
    description = channel.description,
    color = channel.color,
    order = channel.order,
    type = channel.type,
    parent_id = channel.parent_id,
    community_id = channel.community_id,
  })

  return {
    status = 204,
    layout = false
  }
end

return Channel