local encode_json = require 'pgmoon.json'.encode_json
local helpers = require 'lapis.application'
local contains = require 'array'.includes
local map = require 'array'.map
local array = require 'array'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local Channels = require 'models.channels'
local empty = require 'array'.is_empty
local json = require 'cjson'
local MessagesModel = require 'models.messages'
local ReadIndicatorsModel = require 'models.read'
local Mentions = require 'models.mentions'
local Users = require 'models.users'
local push = require 'util.push'
local db = require 'lapis.db'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local validate = require 'util.validate'
local preload = require 'lapis.db.model'.preload
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Messages = {}

function Messages:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    last_message_id = custom_types.uuid:is_optional()
  })

  local channel = helpers.assert_error(Channels:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 1, { 400, 'ChannelNotText' })

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

  local page = params.last_message_id and
    db.query('SELECT * FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM "messages" WHERE "channel_id" = ? order by created_at desc) t WHERE rank > (SELECT rank FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM messages WHERE "channel_id" = ?) t2 WHERE id = ?) LIMIT 25', params.id, params.id, params.last_message_id)
    or MessagesModel:select('WHERE channel_id = ? ORDER BY created_at DESC LIMIT 25', params.id)

  local messages = map(page, function(row)
    local message = {
      id = row.id,
      author_id = row.author_id,
      type = row.type,
      created_at = row.created_at,
      updated_at = row.updated_at,
      content = row.content,
      encrypted_content = row.encrypted_content,
      self_encrypted_content = row.self_encrypted_content,
      rich_content = row.rich_content
    }

    return message
  end)

  if empty(messages) then
    messages = json.empty_array
  end

  return {
    json = messages
  }
end

function Messages:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    content = types.string:length(1, 5000):is_optional(),
    encrypted_content = custom_types.encrypted_message:is_optional(),
    self_encrypted_content = custom_types.encrypted_message:is_optional(),
  })

  local channel = helpers.assert_error(Channels:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 1, { 400, 'ChannelNotText' })
  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.SEND_MESSAGES }), channel), { 403, 'MissingPermissions' })
  end

  if params.encrypted_content or params.self_encrypted_content then
    helpers.assert_error(params.encrypted_content and params.self_encrypted_content, { 400, 'InvalidMessage' })
    helpers.assert_error(not channel.community_id, { 400, 'InvalidMessage' })
    helpers.assert_error(not params.content, { 400, 'InvalidMessage' })
  else
    helpers.assert_error(params.content, { 400, 'InvalidMessage' })
  end

  local row = MessagesModel:create({
    id = uuid(),
    author_id = self.user.id,
    content = params.content,
    channel_id = channel.id,
    type = 1,
    encrypted_content = db.raw(encode_json(params.encrypted_content)),
    self_encrypted_content = db.raw(encode_json(params.self_encrypted_content))
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
    encrypted_content = row.encrypted_content,
    self_encrypted_content = row.self_encrypted_content,
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

  if channel.community_id and engine.has_community_permissions(MembersModel:find({ community_id = channel.community_id, user_id = self.user.id }), Set({ GroupsModel.permissions.MENTION_MEMBERS }), channel) then
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
  elseif not channel.community_id then
    local conversation = channel:get_conversation()
    local participants = conversation:get_participants()
    local tokens = array.flat(map(participants, function(participant)
      local user = participant:get_user()
      if user.id ~= message_event.author.id then
        return user:get_notification_tokens()
      else
        return {}
      end
    end))
    preload(participants, { user = 'notification_tokens' })
    local notifications = {}

    for _, token in ipairs(tokens) do
      table.insert(notifications, {
        platform = token.platform,
        token = token.token,
        payload = {
          title = message_event.author.username,
          subtitle = '',
          body = message_event.content and message_event.content or 'Encrypted Message'
        }
      })
    end

    if not empty(notifications) then
      push({ payloads = notifications })
    end
  end

  return {
    json = message
  }
end

return Messages