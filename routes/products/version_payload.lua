local validate = require 'util.validate'
local VersionsModel = require 'models.versions'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'
local PurchasesModel = require 'models.purchases'

local Payload = {}

function Payload:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    version_id = types.integer + (types.string / tonumber * types.integer)
  })

  local version = helpers.assert_error(VersionsModel:find({ product_id = params.id, number = params.version_id }), { 404, 'VersionNotFound' })
  helpers.assert_error((version:get_product().approved and PurchasesModel:find({
    user_id = self.user.id,
    product_id = version.product_id
  })) or engine.has_community_permissions(helpers.assert_error(MembersModel:find({
    community_id = version:get_product().organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' }), Set({ GroupsModel.permissions.MANAGE_PRODUCTS })) or , { 403, 'MissingPermissions' })

  return {
    json = version.payload
  }
end

return Payload