local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local CommunitiesModel = require 'models.communities'
local MembersModel = require 'models.members'

local Members = {}

function Members:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'user_id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.params.user_id
  }), { 404, 'MemberNotFound' })

  return {
    json = {
      id = member.id,
      user_id = member.user_id,
      created_at = member.created_at,
      updated_at = member.updated_at,
    }
  }
end

return Members