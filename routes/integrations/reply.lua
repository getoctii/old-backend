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
local ResourcesModel = require 'models.resources'
local config = require 'lapis.config'.get()
local validators = require 'resty.jwt-validators'
local jwt = require 'resty.jwt'
local array = require 'array'
local json = require 'cjson'

local Reply = {}

function Reply:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    reply_token = types.string,
    content = types.string:length(1, 5000):is_optional(),
    actions = types.array_of(types.shape {
      type = types.literal('button'),
      content = types.string:length(1, 20),
      action = types.integer / tonumber,
    }):is_optional()
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.id), { 404, 'ResourceNotFound' })
  helpers.assert_error(resource.payload.token == self.req.headers.Authorization, { 403, 'InvalidToken' })
  helpers.assert_error(resource.payload ~= db.NULL, { 400, 'ResourceNotInitalized' })
  helpers.assert_error(resource.type == ResourcesModel.types.SERVER_INTEGRATION, { 400, 'WrongType'})

  local token = jwt:verify(config.jwt.public, params.reply_token, {
    iss = validators.equals('chat.innatical.com'),
    aud = validators.equals('chat.innatical.com'),
    nbf = validators.is_not_before(),
    exp = validators.is_not_expired(),
    type = validators.equals('reply')
  })

  helpers.assert_error(token.verified == true, { 403, 'Unauthorized' })

  local channel = helpers.assert_error(Channels:find({ id = token.payload.sub }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 1, { 400, 'ChannelNotText' })

  -- TODO: Modify these to use integration data

  local row = MessagesModel:create({
    id = uuid(),
    author_id = '30eeda0f-8969-4811-a118-7cefa01098a3',
    content = params.content,
    channel_id = channel.id,
    type = 7,
    rich_content = db.raw(encode_json({
      resource_id = resource.id,
      product_id = resource.product_id,
      actions = array.is_empty(params.actions) and json.empty_array or params.actions
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

return Reply