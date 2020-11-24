local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Invites = require 'models.invites'

local Invite = {}

function Invite:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local invite = helpers.assert_error(Invites:find({ id = self.params.id }), 'InviteNotFound')
  helpers.assert_error(invite:get_community().owner_id == self.user_id, { 403, 'MissingPermissions' })

  assert(invite:delete())

  return {
    layout = false
  }
end

return Invite