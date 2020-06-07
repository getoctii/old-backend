local Users = require 'models.users'
local Invites = require 'models.invities'
local Members = require 'models.members'

local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local uuid = require 'util.uuid'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local invite = helpers.assert_error(Invites:find({ id = self.params.id }), 'InviteNotFound')
  assert(Users:find({ id = self.user_id }))

  Members:create({
    id = uuid(),
    community_id = invite.community_id,
    user_id = self.user_id
  })

  return {
    status = 204
  }
end