local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local Communities = require 'models.communities'
local Members = require 'models.members'
local preload = require 'lapis.db.model'.preload
local MembersModel = require 'models.members'

local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'

local MembersSearch = {}

function MembersSearch:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'query', exists = true, min_length = 1, max_length = 16, matches_pattern = '^%a+$', 'InvalidQuery' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  -- SECURITY: Might want to revisit this query. If we made our username requirements less strict, someone could use metacharacters used for the like operator. This isn't an issue atm.
  local filtered = Members:select("INNER JOIN users u ON members.user_id = u.id WHERE community_id = ? AND u.username LIKE '%' || ? || '%'", community.id, self.params.query)
  preload(filtered, 'user')

  local members = map(filtered, function(row)
    local groups = map(row:get_group_members(), function(group_member)
      return group_member.group_id
    end)

    local member = row:get_user()
    return {
      id = row.id,
      user = {
        id = member.id,
        username = member.username,
        avatar = member.avatar,
        discriminator = member.discriminator
      },
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

return MembersSearch