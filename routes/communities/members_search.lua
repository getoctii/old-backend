local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local Communities = require 'models.communities'
local Members = require 'models.members'
local preload = require 'lapis.db.model'.preload

local map = require 'array'.map
local contains = require 'array'.includes
local empty = require 'array'.is_empty
local json = require 'cjson'

local MembersSearch = {}

function MembersSearch:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'query', exists = true, min_length = 1, max_length = 16, matches_pattern = '^%a+$', 'InvalidQuery' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(contains(map(community:get_members(), function(member)
    return member.user_id
  end), self.user_id), { 403, 'MissingPermissions' })

  -- SECURITY: Might want to revisit this query. If we made our username requirements less strict, someone could use metacharacters used for the like operator. This isn't an issue atm.
  local filtered = Members:select("INNER JOIN users u ON members.user_id = u.id WHERE community_id = ? AND u.username LIKE '%' || ? || '%'", community.id, self.params.query)
  preload(filtered, 'user')

  local members = map(filtered, function(row)
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
      updated_at = row.updated_at
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