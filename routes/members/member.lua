local helpers = require 'lapis.application'
local MembersModel = require 'models.members'
local empty = require 'array'.is_empty
local json = require 'cjson'
local map = require 'array'.map
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Member = {}

function Member:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local member = helpers.assert_error(MembersModel:find({ id = params.id }), 'MemberNotFound')

  helpers.assert_error(MembersModel:find({
    community_id = member.community_id,
    user_id = self.user.id
  }), { 404, 'MemberNotFound' })

  local groups = member:get_group_members()
  local permissions = engine.retrieve_permissions(member)

  return {
    json = {
      id = member.id,
      user_id = member.user_id,
      created_at = member.created_at,
      updated_at = member.updated_at,
      groups = empty(groups) and json.empty_array or map(groups, function(group_member)
        return group_member.group_id
      end),
      highest_order = engine.get_highest_order(member),
      permissions = empty(permissions) and json.empty_array or Set.values(permissions)
    }
  }
end

return Member