local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local ChannelsModel = require 'models.channels'
local array = require 'array'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local IntegrationsModel = require 'models.integrations'
local preload = require 'lapis.db.model'.preload
local db = require 'lapis.db'
local broadcast = require 'util.broadcast'
local json = require 'cjson'
local generateReplyToken = require 'util.reply'

local Execute = {}

function Execute:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid,
    name = types.string,
    params = types.array_of(types.string)
  })

  local channel = helpers.assert_error(ChannelsModel:find({ id = params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.community_id, { 400, 'InvalidChannel' })
  helpers.assert_error(channel.type == 1, { 400})
  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.SEND_MESSAGES }), channel), { 403, 'MissingPermissions' })

  local integrations = IntegrationsModel:select('WHERE community_id = ?', channel.community_id)
  preload(integrations, 'resource')

  local resources = array.map(integrations, function(integration)
    return integration:get_resource()
  end)

  helpers.assert_error(array.includes(array.map(resources, function(resource) return resource.id end), params.resource_id), { 400, 'InvalidResource' })
  local index = array.index_of(array.map(resources, function(resource) return resource.id end), params.resource_id)
  local resource = resources[index]

  helpers.assert_error(resource.commands ~= db.NULL, { 400, 'InvalidResource' })
  helpers.assert_error(array.includes(array.map(resource.commands, function(command) return command.name end), params.name), {404, 'CommandNotFound' })
  local command_index = array.index_of(array.map(resource.commands, function(command) return command.name end), params.name)
  local command = resource.commands[command_index]

  helpers.assert_error(#command.params == #params.params, { 400, 'InvalidInvocation' })

  broadcast('integration:' .. resource.id, 'NEW_INVOCATION', {
    name = command.name,
    params = array.is_empty(params.params) and json.empty_array or params.params,
    channel_id = channel.id,
    reply_token = generateReplyToken(channel.id)
  })

  return {
    layout = false
  }
end

return Execute