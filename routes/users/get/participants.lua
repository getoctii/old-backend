local Users = require 'models.users'
local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local preload = require 'lapis.db.model'.preload
local Read = require 'models.read'

local json = require 'cjson'

local map = require 'util.map'
local empty = require 'util.empty'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })

  helpers.assert_error(self.params.id == self.user_id, { 403, 'InvalidUser' })

  local participants = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' }):get_participants()
  preload(participants, { conversation = { 'participants', 'channel'} })

  local participant_stubs = map(participants, function(row)
    local conversation = row:get_conversation()
    local all_participants = conversation:get_participants()
    local channel = conversation:get_channel()
    local pager = channel:get_messages_paginated({
      per_page = 1,
      ordered = {
        'created_at'
      },
      order = 'desc'
    })
    return {
      id = row.id,
      conversation = {
        id = conversation.id,
        channel_id = conversation.channel_id,
        -- TODO: This might be a bit inefficent, refactor.
        last_message_id = (pager:get_page()[1] or {}).id,
        participants = map(all_participants, function(row)
            return row.user_id
        end)
      }
    }
  end)

  if empty(participant_stubs) then
    participant_stubs = json.empty_array
  end

  return {
    json = participant_stubs
  }
end