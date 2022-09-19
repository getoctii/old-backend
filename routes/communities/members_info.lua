local helpers = require 'lapis.application'
local CommunitiesModel = require 'models.communities'
local MembersModel = require 'models.members'
local empty = require 'array'.is_empty
local json = require 'cjson'
local map = require 'array'.map
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Members = {}

function Members:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    user_id = custom_types.uuid
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = params.user_id
  }), { 404, 'MemberNotFound' })

  local groups = map(member:get_group_members(), function(group_member)
    return group_member.group_id
  end)

  return {
    json = {
      id = member.id,
      user_id = member.user_id,
      created_at = member.created_at,
      updated_at = member.updated_at,
      groups = empty(groups) and json.empty_array or groups
    }
  }
end

return Members