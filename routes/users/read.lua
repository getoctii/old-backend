local Users = require 'models.users'
local ReadIndicators = require 'models.read'
local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local preload = require 'lapis.db.model'.preload

local map = require 'array'.map
local flatten = require 'array'.flat
local array = require 'array'

local Read = {}

function Read:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.params.id == self.user.id, { 403, 'InvalidUser' })
  local members = self.user:get_members()
  local participants = self.user:get_participants()

  preload(members, { community = 'channels' })
  preload(participants, { conversation = 'channel' })

  local communities = map(members, function(row) return row:get_community() end)
  local community_channels = flatten(map(communities, function(row) return row:get_channels() end ))
  local conversation_channels = map(participants, function(row) return row:get_conversation():get_channel() end)

  local channels = flatten({community_channels, conversation_channels})
  local channel_ids = map(channels, function(row) return row.id end)

  local read_indicators_raw = ReadIndicators:find_all(channel_ids, {
    key = 'channel_id',
    where = {
      user_id = self.user.id
    }
  })

  local read_indicators = {}

  array.each(read_indicators_raw, function(row)
    read_indicators[row.channel_id] = row
  end)

  local res = {}

  array.each(channels, function(row)
    -- TODO: Inefficient
    local pager = row:get_messages_paginated({
      per_page = 1,
      ordered = {
        'created_at'
      },
      order = 'desc'
    })

    res[row.id] = {
      last_message_id = (pager:get_page()[1] or {}).id,
      read = (read_indicators[row.id] or {}).last_read_id
    }
  end)

  return {
    json = res
  }
end

return Read