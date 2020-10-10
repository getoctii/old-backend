local Users = require 'models.users'
local Invites = require 'models.invites'
local Members = require 'models.members'

local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'

local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local uuid = require 'util.uuid'

return function(self)
  validate.assert_valid(self.params, {
    { 'code', exists = true, is_uuid = true, 'InvalidCode' }
  })

  local invite = helpers.assert_error(Invites:find({ code = self.params.code }), 'InviteNotFound')
  helpers.assert_error(not Members:find({ community_id = invite.community_id, user_id = self.user_id }), { 400, 'AlreadyInCommunity' })

  local community = invite:get_community()

  local member = assert(Members:create({
    id = uuid(),
    community_id = invite.community_id,
    user_id = self.user_id
  }))

  broadcast('user:' .. self.user_id, 'NEW_MEMBER', { -- Send in same event
    id = member.id,
    community = {
      id = community.id,
      icon = community.icon,
      name = community.name,
      large = community.large,
      owner_id = community.owner_id
    }
  })

  resubscribe('user:' .. self.user_id)

  broadcast('community:' .. community.id, 'JOIN_MEMBER', {
    id = member.id,
    community_id = community.id,
    user_id = self.user_id
  })

  return {
    status = 200,
    json = {
      community_id = invite.community_id
    }
  }
end