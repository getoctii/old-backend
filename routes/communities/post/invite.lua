local Communities = require 'models.communities'

local Invites = require 'models.invites'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'

local uuid = require 'util.uuid'
local contains = require 'util.contains'
local map = require 'util.map'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(community.owner_id == self.user_id, { 403, 'MissingPermissions' })

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