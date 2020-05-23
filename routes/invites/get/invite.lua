local Invites = require 'models.invities'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'

local json = require 'cjson'

local map = require 'util.map'
local empty = require 'util.empty'


return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local invite = helpers.assert_error(Invites:find({ id = self.params.id }), 'InviteNotFound')

  return {
    json = {
      id = invite.id,
      code = invite.code
    }
  }
end