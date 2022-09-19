local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local db = require 'lapis.db'
local config = require 'lapis.config'.get()
local helpers = require 'lapis.application'

local Started = {}

function Started:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
  })

  local token = config.voice_token

  helpers.assert_error(self.req.headers.Authorization == token, { 403, 'Unauthorized' })

  assert(db.delete('voice_rooms', { server = params.id }))

  return {
    layout = false
  }
end

return Started