local helpers = require 'lapis.application'
local CommunitiesModel = require 'models.communities'
local MembersModel = require 'models.members'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local db = require 'lapis.db'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

-- local leaveMessages = {
--   ' left the community :(',
--   ' has left, guess they didn\'t like the community...',
--   ' left, didn\'t like them anyways.',
--   ' has left, they will be missed.',
--   ' left, they will return someday!'
-- }

local Leave = {}

function Leave:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(community.owner_id ~= self.user.id, { 403, 'MissingPermissions' })

  local member = MembersModel:find({ user_id = self.user.id, community_id = community.id })

  member:delete()

  broadcast('user:' .. self.user.id, 'DELETED_MEMBER', {
    id = member.id,
    community_id = community.id
  })

  resubscribe('user:' .. self.user.id)

  return {
    layout = false
  }
end

return Leave