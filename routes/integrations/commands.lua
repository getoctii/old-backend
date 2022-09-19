local types = require 'tableshape'.types
local validate = require 'util.validate'
local ResourcesModel = require 'models.resources'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
local encode_json = require 'pgmoon.json'.encode_json
local array = require 'array'
local json = require 'cjson'
local custom_types = require 'util.types'

local Commands = {}

local commands_type = types.array_of(types.shape {
  name = types.string:length(1, 10) * types.pattern('^%l+$'),
  description = types.string:length(1, 30),
  params = types.array_of(types.shape {
    name = types.string:length(1, 10) * types.pattern('^%l+$'),
    type = types.string:length(1, 10) * types.pattern('^%l+$')
  })
})

function Commands:PUT()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    commands = commands_type
  })
  local resource = helpers.assert_error(ResourcesModel:find(params.id), { 404, 'ResourceNotFound' })
  helpers.assert_error(resource.payload.token == self.req.headers.Authorization, { 403, 'InvalidToken' })
  helpers.assert_error(resource.payload ~= db.NULL, { 400, 'ResourceNotInitalized' })
  helpers.assert_error(resource.type == ResourcesModel.types.SERVER_INTEGRATION, { 400, 'WrongType'})
  local cleaned = array.map(params.commands, function(command)
    return {
      name = command.name,
      description = command.description,
      params = array.is_empty(command.params) and json.empty_array or command.params
    }
  end)

  resource:update({
    commands = db.raw(encode_json(array.is_empty(cleaned) and json.empty_array or cleaned))
  })

  return {
    layout = false
  }
end

return Commands