local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local helpers = require 'lapis.application'

local Message = require 'models.messages'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' } }
  })

  local message = helpers.assert_error(Message:find({ id = self.params.id }), { 404, 'MessageNotFound' })

  return {
    json = {
      id = message.id,
      created_at = message.created_at,
      updated_at = message.updated_at,
      content = message.content,
      channel_id = message.channel_id,
      author_id = message.author_id
    }
  }
end