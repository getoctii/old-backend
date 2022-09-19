local encode_json = require 'pgmoon.json'.encode_json
local helpers = require 'lapis.application'
local map = require 'array'.map
local contains = require 'array'.includes
local broadcast = require 'util.broadcast'
local db = require 'lapis.db'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local MembersModel = require 'models.members'
local Set = require 'pl.Set'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Messages = require 'models.messages'

local Message = {}

function Message:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local message = helpers.assert_error(Messages:find({ id = params.id }), { 404, 'MessageNotFound' })
  local channel = message:get_channel()

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'MessageNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES }), channel), { 403, 'MissingPermissions' })
  end

  return {
    json = {
      id = message.id,
      created_at = message.created_at,
      updated_at = message.updated_at,
      content = message.content,
      channel_id = message.channel_id,
      author_id = message.author_id,
      encrypted_content = message.encrypted_content,
      self_encrypted_content = message.self_encrypted_content,
      rich_content = message.rich_content
    }
  }

end

function Message:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    content = types.string:length(1, 5000):is_optional(),
    encrypted_content = custom_types.encrypted_message:is_optional(),
    self_encrypted_content = custom_types.encrypted_message:is_optional(),
  })

  local message = helpers.assert_error(Messages:find({ id = params.id }), { 404, 'MessageNotFound' })
  local channel = message:get_channel()
  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'MessageNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.SEND_MESSAGES }), channel), { 403, 'MissingPermissions' })
  end
  helpers.assert_error(message:get_author().id == self.user.id, { 403, 'MissingPermissions' })

  if params.encrypted_content or params.self_encrypted_content then
    helpers.assert_error(params.encrypted_content and params.self_encrypted_content, { 400, 'InvalidMessage' })
    helpers.assert_error(not channel.community_id, { 400, 'InvalidMessage' })
    helpers.assert_error(not params.content, { 400, 'InvalidMessage' })
    helpers.assert_error(message.encrypted_content and message.self_encrypted_content, { 400, 'InvalidMessage' })
  else
    helpers.assert_error(params.content, { 400, 'InvalidMessage' })
    helpers.assert_error(message.content, { 400, 'InvalidMessage' })
  end

  message:update({
    content = params.content,
    encrypted_content = db.raw(encode_json(params.encrypted_content)),
    self_encrypted_content = db.raw(encode_json(params.self_encrypted_content))
  })

  message:refresh()
  local message_event = {
    id = message.id,
    channel_id = message.channel_id,
    updated_at = message.updated_at,
    content = message.content,
    encrypted_content = message.encrypted_content,
    self_encrypted_content = message.self_encrypted_content
  }

  broadcast('channel:' .. channel.id, 'UPDATED_MESSAGE', message_event)

  return {
    layout = false,
    status = 204
  }
end

function Message:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local message = helpers.assert_error(Messages:find({ id = params.id }), { 404, 'MessageNotFound' })
  local channel = message:get_channel()

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'MessageNotFound' })
    if not engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_MESSAGES })) then
      helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.SEND_MESSAGES }), channel), { 403, 'MissingPermissions' })
      helpers.assert_error(message:get_author().id == self.user.id, { 403, 'MissingPermissions' })
    end
  end
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