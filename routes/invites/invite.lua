local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Invites = require 'models.invites'
local Communities = require 'models.communities'
local db = require 'lapis.db'

local Invite = {}

function Invite:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidCode' }
  })

  local invite = helpers.assert_error(Invites:find({ code = self.params.id }), 'InviteNotFound')
  local community = invite:get_community()

  return {
    json = {
      id = invite.id,
      code = invite.code,
      author_id = invite.author_id,
      created_at = invite.created_at,
      updated_at = invite.updated_at,
      uses = invite.uses,
      community = {
        id = community.id,
        name = community.name,
        icon = community.icon,
        large = community.large,
        owner_id = community.owner_id
      }
    }
  }
end

function Invite:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local invite = helpers.assert_error(Invites:find({ id = self.params.id }), 'InviteNotFound')
  helpers.assert_error(invite:get_community().owner_id == self.user_id, { 403, 'MissingPermissions' })

  assert(db.delete('invites', {
    id = invite.id
  }))

  return {
    layout = false
  }
end

return Invite