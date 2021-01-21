local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Communities = require 'models.communities'
local contains = require 'array'.includes
local map = require 'array'.map
local Members = require 'models.members'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local db = require 'lapis.db'

local Leave = {}

function Leave:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(contains(map(community:get_members(), function(member)
    return member.user_id
  end), self.user.id), { 403, 'MissingPermissions' })
  helpers.assert_error(community.owner_id ~= self.user.id, { 403, 'MissingPermissions' })

  local member = Members:find({ user_id = self.user.id, community_id = community.id })

  -- TODO: investigate why obj:delete() errors
  assert(db.delete('members', {
    id = member.id
  }))

  broadcast('user:' .. self.user.id, 'DELETED_MEMBER', {
    id = member.id
  })

  resubscribe('user:' .. self.user.id)

  return {
    layout = false
  }
end

return Leave