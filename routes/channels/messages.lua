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
local ReadIndicatorsModel = require 'models.read'
local Mentions = require 'models.mentions'
local Users = require 'models.users'
local push = require 'util.push'
local db = require 'lapis.db'

local Messages = {}

function Messages:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })
  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
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
      type = row.type,
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
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    helpers.assert_error(contains(map(channel:get_community():get_members(), function(member)
      return member.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  end

  local row = MessagesModel:create({
    id = uuid(),
    author_id = self.user.id,
    content = self.params.content,
    channel_id = channel.id,
    type = 1
  })

  local author = row:get_author()

  local message = {
    id = row.id,
    type = row.type,
    created_at = row.created_at,
    updated_at = row.updated_at,
    content = row.content
  }

  local message_event = {
    id = row.id,
    type = row.type,
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

  local read = ReadIndicatorsModel:find({ user_id = self.user.id, channel_id = channel.id })

  if not read then
    assert(ReadIndicatorsModel:create({
      user_id = self.user.id,
      channel_id = channel.id,
      last_read_id = message.id
    }))
  else
    assert(read:update({
      last_read_id = message.id
    }))
  end

  db.query('UPDATE mentions SET read = true FROM messages WHERE mentions.message_id = messages.id AND messages.channel_id = ?', channel.id)

  local mentioned_users = {}

  -- TODO: Cleanup
  for match in ngx.re.gmatch(message.content, '<@([A-Za-z0-9-]+?)>') do
    local user_id = match[1]
    if (not channel.community_id and
      contains(map(channel:get_conversation():get_participants(), function(participant) return participant.user_id end), user_id))
      or contains(map(channel:get_community():get_members(), function(member) return member.user_id end), user_id) then
        mentioned_users[user_id] = true
    end
  end

  local parsed_content = ngx.re.gsub(message_event.content,'<@([A-Za-z0-9-]+?)>', function(match)
    return '@' .. ((Users:find(match[1]) or {}).username or 'unknown')
  end)

  local notifications = {}

  for user_id in pairs(mentioned_users) do
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

    local user = Users:find(user_id)
    if (user.state ~= Users.states.dnd) and ((not user.last_ping) or ((os.time() - user.last_ping) > 180)) then
      local tokens = user:get_notification_tokens()

      for _, token in ipairs(tokens) do
        table.insert(notifications, {
          platform = token.platform,
          token = token.token,
          payload = {
            title = message_event.community_name and message_event.community_name or message_event.author.username,
            subtitle = message_event.channel_name and ('#' .. message_event.channel_name) or '',
            body = (message_event.community_name and (message_event.author.username .. ': ') or '') .. parsed_content
          }
        })
      end
    end
  end

  if not empty(notifications) then
    push({ payloads = notifications })
  end

  return {
    json = message
  }
end

return Messages