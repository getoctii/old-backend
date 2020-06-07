local Invites = require 'models.invites'
local validate = require 'lapis.validate'

local uuid = require 'util.uuid'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local invite = Invites:create({
    id = uuid(),
    community_id = self.params.id
  })

  return {
    json = {
      id = invite.id
    }
  }
end