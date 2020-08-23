local helpers = require 'lapis.application'
local validate = require 'lapis.validate'

local Conversations = require 'models.conversations'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' } }
  })

  local conversation = helpers.assert_error(Conversations:find({ id = self.params.id }), { 404, 'ConversationNotFound' })

  return {
    json = {
      id = conversation.id,
      channel_id = conversation.get_channel().id
    }
  }
end