local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local helpers = require 'lapis.application'

local Message = require 'models.messages'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local message = helpers.assert_error(Message:find({ id = self.params.id }), 'MessageNotFound')
  assert(message:delete())

  return {}
end
