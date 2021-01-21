local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local map = require 'array'.map
local contains = require 'array'.includes
local broadcast = require 'util.broadcast'
local db = require 'lapis.db'

local Messages = require 'models.messages'

local Message = {}

function Message:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' } }
  })

  local message = helpers.assert_error(Messages:find({ id = self.params.id }), { 404, 'MessageNotFound' })
  local channel = message:get_channel()

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  end

  return {
    json = {
      id = message.id,
      created_at = message.created_at,
      updated_at = message.updated_at,
      content = message.content,
      channel_id = message.channel_id,
      author_id = message.author_id
    }
  }

end

function Message:PATCH()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' } },
    { 'content', exists = true, min_length = 1, max_length = 2000, 'InvalidMessage'}
  })
  local message = helpers.assert_error(Messages:find({ id = self.params.id }), { 404, 'MessageNotFound' })
  local channel = message:get_channel()
  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  end
  helpers.assert_error(message:get_author().id == self.user.id, { 403, 'MissingPermissions' })
  message:update({
    content = self.params.content
  })
  message:refresh()
  local message_event = {
    id = message.id,
    channel_id = message.channel_id,
    updated_at = message.updated_at,
    content = message.content
  }

  broadcast('channel:' .. channel.id, 'UPDATED_MESSAGE', message_event)
  return {
    layout = false,
    status = 204
  }
end


function Message:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local message = helpers.assert_error(Messages:find({ id = self.params.id }), { 404, 'MessageNotFound' })
  local channel = message:get_channel()

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  end

  helpers.assert_error(message:get_author().id == self.user.id, { 403, 'MissingPermissions' })

  -- assert(db.delete('read', { last_read_id = message.id }))
  assert(db.delete('mentions', { message_id = message.id }))
  assert(db.delete('messages', { id = message.id }))

  broadcast('channel:' .. channel.id, 'DELETED_MESSAGE', {
    id = message.id,
    channel_id = channel.id
  })

  return {
    layout = false
  }

end

return Message