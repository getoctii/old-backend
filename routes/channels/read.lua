local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Channels = require 'models.channels'
local contains = require 'array'.includes
local map = require 'array'.map
local ReadIndicators = require 'models.read'


local Read = {}

function Read:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user_id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user_id), { 403, 'MissingPermissions' })
  end

  local read = ReadIndicators:find({ user_id = self.user_id, channel_id = channel.id })

  local pager = channel:get_messages_paginated({
    per_page = 1,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  if not read then
    assert(ReadIndicators:create({
      user_id = self.user_id,
      channel_id = channel.id,
      last_read_id = (pager:get_page()[1] or {}).id
    }))
  else
    assert(read:update({
      last_read_id = (pager:get_page()[1] or {}).id
    }))
  end

  return {
    layout = false,
    status = 204
  }
end

return Read