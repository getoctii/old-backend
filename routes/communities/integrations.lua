local IntegrationsModel = require 'models.integrations'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local validate = require 'util.validate'
local array = require 'array'
local json = require 'cjson'
local preload = require 'lapis.db.model'.preload
local helpers = require 'lapis.application'
local Communities = require 'models.communities'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local db = require 'lapis.db'

local Integrations = {}

function Integrations:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES })), { 403, 'MissingPermissions' })

  local integrations = IntegrationsModel:select('WHERE community_id = ?', params.id)
  preload(integrations, { resource = 'product' })

  local mapped = array.map(integrations, function(integration)
    local resource = integration:get_resource()
    local product = resource:get_product()

    if resource.commands == db.NULL then
      return {
        id = resource.id,
        name = resource.name,
        icon = product.icon,
        commands = json.empty_array
      }
    end

    local cleaned = array.map(resource.commands, function(command)
      return {
        name = command.name,
        description = command.description,
        params = array.is_empty(command.params) and json.empty_array or command.params
      }
    end)

    return {
      id = resource.id,
      name = resource.name,
      icon = product.icon,
      commands = array.is_empty(cleaned) and json.empty_array or cleaned
    }
  end)

  return {
    json = array.is_empty(mapped) and json.empty_array or mapped
  }
end

function Integrations:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })

  -- TODO: check ownership
  IntegrationsModel:create({
    community_id = community.id,
    resource_id = params.resource_id
  })

  return {
    layout = false
  }
end

function Integrations:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_COMMUNITY })), { 403, 'MissingPermissions' })

  local integration = Integrations:find({
    community_id = community.id,
    resource_id = params.resource_id
  })

  integration:delete()

  return {
    layout = false
  }
end

return Integrations