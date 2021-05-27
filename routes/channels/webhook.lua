local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local Channels = require 'models.channels'
local helpers = require 'lapis.application'
local broadcast = require 'util.broadcast'
local MessagesModel = require 'models.messages'
local uuid = require 'util.uuid'
local encode_json = require 'pgmoon.json'.encode_json
local db = require 'lapis.db'

local Webhook = {}

function Webhook:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    code = custom_types.uuid,
    username = custom_types.username,
    avatar = custom_types.image,
    content = types.string:length(1, 5000):is_optional()
  })

  local channel = helpers.assert_error(Channels:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 1, { 400, 'ChannelNotText' })
  helpers.assert_error(channel.community_id, { 400, 'WrongChannel' })
  helpers.assert_error(channel.webhook_code == params.code, { 403, 'WrongCode' })

  local row = MessagesModel:create({
    id = uuid(),
    author_id = '30eeda0f-8969-4811-a118-7cefa01098a3',
    content = params.content,
    channel_id = channel.id,
    type = 6,
    rich_content = db.raw(encode_json({
      username = params.username,
      avatar = params.avatar
    }))
  })

  local author = row:get_author()

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
    },
    rich_content = row.rich_content
  }

  local community = channel:get_community()
  message_event.community_id = channel.community_id
  message_event.community_name = community.name
  message_event.channel_name = channel.name

  broadcast('channel:' .. channel.id, 'NEW_MESSAGE', message_event)

  return {
    layout = false
  }
end

return Webhook