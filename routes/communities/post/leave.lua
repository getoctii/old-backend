local Members = require 'models.members'
local Communities = require 'models.communities'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'

local json = require 'cjson'

local map = require 'util.map'
local empty = require 'util.empty'
local contains = require 'util.contains'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(contains(map(community:get_members(), function(member)
    return member.user_id
  end), self.user_id), { 403, 'MissingPermissions' })
  helpers.assert_error(community.owner_id ~= self.user_id, { 403, 'MissingPermissions' })

  local member = Members:find({ user_id = self.user_id, community_id = community.id })

  member:delete()

  broadcast('user:' .. self.user_id, 'DELETED_MEMBER', {
    id = member.id
  })

  resubscribe('user:' .. self.user_id)

  return {
    layout = false
  }
end