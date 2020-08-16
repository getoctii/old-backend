local Invites = require 'models.invites'
local validate = require 'lapis.validate'

local uuid = require 'util.uuid'

return function(self)
  print('Hello World!')
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local invite = Invites:create({
    id = uuid(),
    code = uuid(),
    community_id = self.params.id,
    author_id = self.user_id,
    uses = 0
  })

  return {
    json = {
      id = invite.id,
      code = invite.code,
      created_at = invite.created_at,
      updated_at = invite.updated_at
    }
  }
end