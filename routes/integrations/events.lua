local helpers = require 'lapis.application'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local ResourcesModel = require 'models.resources'
local db = require 'lapis.db'

local Events = {}

function Events:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    authorization = types.string:is_optional()
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.id), { 404, 'ResourceNotFound' })
  helpers.assert_error(resource.payload ~= db.NULL, { 400, 'ResourceNotInitalized' })
  helpers.assert_error(resource.payload.token == params.authorization or resource.payload.token == self.req.headers.Authorization, { 403, 'InvalidToken' })
  helpers.assert_error(resource.type == ResourcesModel.types.SERVER_INTEGRATION, { 400, 'WrongType'})

  return {
    layout = false,
    headers = {
      ['Grip-Hold'] = 'stream',
      ['Grip-Channel'] = 'integration:' .. params.id,
      ['Content-Type'] = 'text/event-stream',
      ['Grip-Keep-Alive'] = '\\n; format=cstring; timeout=30',
      ['Grip-Link'] = string.format('</integrations/%s/events?authorization=%s>; rel=next', params.id, params.authorization or self.req.headers.Authorization)
    }
  }

end

return Events