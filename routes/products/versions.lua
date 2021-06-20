local encode_json = require 'pgmoon.json'.encode_json
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local array = require 'array'
local json = require 'cjson'
local ProductsModel = require 'models.products'
local VersionsModel = require 'models.versions'
local ResourcesModel = require 'models.resources'
local db = require 'lapis.db'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

local Versions = {}

function Versions:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  helpers.assert_error(product.approved or engine.has_community_permissions(helpers.assert_error(MembersModel:find({
    community_id = product.organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' }), Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  local versions = VersionsModel:select('WHERE product_id = ? ORDER BY number ASC', product.id)

  local version_ids = array.map(versions, function(version)
    return version.number
  end)

  return {
    json = array.is_empty(version_ids) and json.empty_array or version_ids
  }
end

function Versions:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    name = custom_types.community_name,
    description = types.string:length(0, 140)
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = product.organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })
  local versions = VersionsModel:select('WHERE product_id = ? ORDER BY number ASC', product.id)

  local next_number = #versions > 0 and versions[#versions].number + 1 or 1

  local resources = product:get_resources()
  local themes = array.map(array.filter(resources, function(resource)
    return resource.type == ResourcesModel.types.THEME and resources.payload ~= db.NULL
  end), function(resource)
    return resource.payload
  end)

  local server_integrations = array.map(array.filter(resources, function(resource)
    return resource.type == ResourcesModel.types.SERVER_INTEGRATION and resources.payload ~= db.NULL
  end), function(resource)
    return {
      id = resource.id,
      name = resource.name
    }
  end)

  local payload = {
    themes = array.is_empty(themes) and json.empty_array or themes,
    client = json.empty_array,
    server = array.is_empty(server_integrations) and json.empty_array or server_integrations
  }

  local version = VersionsModel:create({
    name = params.name,
    description = params.description,
    product_id = product.id,
    number = next_number,
    payload = db.raw(encode_json(payload))
  })

  return {
    status = 201,
    json = {
      name = version.name,
      description = version.description,
      number = version.number
    }
  }
end

return Versions