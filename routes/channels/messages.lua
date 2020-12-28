local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local contains = require 'array'.includes
local map = require 'array'.map
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local Channels = require 'models.channels'
local preload = require 'lapis.db.model'.preload
local empty = require 'array'.is_empty
local json = require 'cjson'
local MessagesModel = require 'models.messages'
local ReadIndicators = require 'models.read'
local Mentions = require 'models.mentions'

local Messages = {}

function Messages:GET()
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

  local pager = channel:get_messages_paginated({
    per_page = 25,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  local page = pager:get_page(self.params.created_at)
  preload(page, 'author')

  local messages = map(page, function(row)
    local author = row:get_author()
    return {
      id = row.id,
      author = {
        id = author.id,
        username = author.username,
        avatar = author.avatar,
        discriminator = author.discriminator
      },
      created_at = row.created_at,
      updated_at = row.updated_at,
      content = row.content
    }
  end)

  if empty(messages) then
    messages = json.empty_array
  end

  return {
    json = messages
  }
end

function Messages:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'content', exists = true, min_length = 1, max_length = 2000, 'InvalidMessage'}
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

  local row = MessagesModel:create({
    id = uuid(),
    author_id = self.user_id,
    content = self.params.content,
    channel_id = channel.id
  })

  local author = row:get_author()

  local message = {
    id = row.id,
    created_at = row.created_at,
    updated_at = row.updated_at,
    content = row.content
  }

  local message_event = {
    id = row.id,
    created_at = row.created_at,
    updated_at = row.updated_at,
    content = row.content,
    channel_id = row.channel_id,
    author = {
      id = author.id,
      username = author.username,
      avatar = author.avatar,
      discriminator = author.discriminator
    }
  }

  if channel.community_id then
    local community = channel:get_community()
    message_event.community_id = channel.community_id
    message_event.community_name = community.name
    message_event.channel_name = channel.name
  end

  broadcast('channel:' .. channel.id, 'NEW_MESSAGE', message_event)

  local read = ReadIndicators:find({ user_id = self.user_id, channel_id = channel.id })

  if not read then
    assert(ReadIndicators:create({
      user_id = self.user_id,
      channel_id = channel.id,
      last_read_id = message.id
    }))
  else
    assert(read:update({
      last_read_id = message.id
    }))
  end

  -- TODO: Cleanup
  for match in ngx.re.gmatch(message.content, '<@([A-Za-z0-9-]+?)>') do
    local user_id = match[1]
    if (not channel.community_id and
      contains(map(channel:get_conversation():get_participants(), function(participant) return participant.user_id end), user_id))
      or contains(map(channel:get_community():get_members(), function(member) return member.user_id end), user_id) then
      Mentions:create({
        id = uuid(),
        user_id = user_id,
        message_id = message.id,
        read = false
      })

      broadcast('user:' .. user_id, 'NEW_MENTION', {
        id = uuid(),
        user_id = user_id,
        message_id = message.id,
        read = false,
        channel_id = channel.id
      })
    end
  end

  return {
    json = message
  }
end

return Messages