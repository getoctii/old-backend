local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local CommunitiesModel = require 'models.communities'
local preload = require 'lapis.db.model'.preload
local MembersModel = require 'models.members'
local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'
local db = require 'lapis.db'

local Members = {}

function Members:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(CommunitiesModel:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  local page = self.params.last_member_id and
    db.query('SELECT * FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM "members" WHERE "community_id" = ? order by created_at desc) t WHERE rank > (SELECT rank FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM members WHERE "community_id" = ?) t2 WHERE id = ?) LIMIT 25', self.params.id, self.params.id, self.params.last_member_id)
    or MembersModel:select('WHERE community_id = ? ORDER BY created_at DESC LIMIT 25', self.params.id)

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