local validate = require 'util.validate'
local ResourcesModel = require 'models.resources'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'

local Resources = {}

--TODO:permissions, and extra validation
function Resources:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })

  return {
    json = {
      id = resource.id,
      name = resource.name,
      type = resource.type
    }
  }
end

function Resources:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid,
    name = custom_types.community_name:is_optional(),
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })

  resource:update({
    name = params.name
  })

  return {
    layout = false,
    status = 200
  }
end

function Resources:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })
  resource:delete()

  return {
    layout = false,
    status = 200
  }
end

return Resources