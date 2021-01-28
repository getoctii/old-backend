local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local MembersModel = require 'models.members'
local empty = require 'array'.is_empty
local json = require 'cjson'
local map = require 'array'.map

local Member = {}

function Member:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidMemberUUID' }
  })

  local member = helpers.assert_error(MembersModel:find({ id = self.params.id }), 'MemberNotFound')

  helpers.assert_error(MembersModel:find({
    community_id = member.community_id,
    user_id = self.user.id
  }), { 404, 'MemberNotFound' })

  local groups = member:get_group_members()

  return {
    json = {
      id = member.id,
      user_id = member.user_id,
      created_at = member.created_at,
      updated_at = member.updated_at,
      groups = empty(groups) and json.empty_array or map(groups, function(group_member)
        return group_member.group_id
      end)
    }
  }
end

return Member