local helpers = require 'lapis.application'
local CommunitiesModel = require 'models.communities'
local preload = require 'lapis.db.model'.preload
local MembersModel = require 'models.members'
local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'
local db = require 'lapis.db'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Members = {}

function Members:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    last_member_id = custom_types.uuid:is_optional()
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  local page = params.last_member_id and
    db.query('SELECT * FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM "members" WHERE "community_id" = ? order by created_at desc) t WHERE rank > (SELECT rank FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM members WHERE "community_id" = ?) t2 WHERE id = ?) LIMIT 25', params.id, params.id, params.last_member_id)
    or MembersModel:select('WHERE community_id = ? ORDER BY created_at DESC LIMIT 25', params.id)

  MembersModel:load_all(page)
  preload(page, 'group_members')

  local members = map(page, function(row)
    local groups = map(row:get_group_members(), function(group_member)
      return group_member.group_id
    end)

    return {
      id = row.id,
      user_id = row.user_id,
      created_at = row.created_at,
      updated_at = row.updated_at,
      groups = empty(groups) and json.empty_array or groups
    }
  end)

  if empty(members) then
    members = json.empty_array
  end

  return {
    json = members
  }
end

return Members