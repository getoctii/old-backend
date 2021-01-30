local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Channels = require 'models.channels'
local contains = require 'array'.includes
local map = require 'array'.map
local ReadIndicators = require 'models.read'
local db = require 'lapis.db'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'

local Read = {}

function Read:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })

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

  local read = ReadIndicators:find({ user_id = self.user.id, channel_id = channel.id })

  local pager = channel:get_messages_paginated({
    per_page = 1,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  if not read then
    assert(ReadIndicators:create({
      user_id = self.user.id,
      channel_id = channel.id,
      last_read_id = (pager:get_page()[1] or {}).id
    }))
  else
    assert(read:update({
      last_read_id = (pager:get_page()[1] or {}).id
    }))
  end

  db.query('UPDATE mentions SET read = true FROM messages WHERE mentions.message_id = messages.id AND messages.channel_id = ?', channel.id)

  return {
    layout = false,
    status = 204
  }
end

return Read