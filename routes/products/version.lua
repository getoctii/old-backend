local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local ProductsModel = require 'models.products'
local VersionsModel = require 'models.versions'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'

local Version = {}

function Version:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    version_id = types.integer + (types.string / tonumber * types.integer)
  })

  local product = helpers.assert_error(ProductsModel:find(params.id), { 404, 'ProductNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = product.organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(product.approved or engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  local version = helpers.assert_error(VersionsModel:find({ product_id = product.id, number = params.version_id }), { 404, 'VersionNotfound' })

  return {
    json = {
      name = version.name,
      description = version.description,
      number = version.number
    }
  }
end

return Version