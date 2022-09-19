local helpers = require 'lapis.application'
local Communities = require 'models.communities'
local Members = require 'models.members'
local preload = require 'lapis.db.model'.preload
local MembersModel = require 'models.members'

local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'

local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local sanitize_sql_like = require 'util.sanitize_sql_like'

local MembersSearch = {}

function MembersSearch:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    query = types.string:length(1, 16) * types.pattern('^%a+$')
  })

  local community = helpers.assert_error(Communities:find({ id = params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  local filtered = Members:select("INNER JOIN users u ON members.user_id = u.id WHERE community_id = ? AND u.username ILIKE '%' || ? || '%'", community.id, sanitize_sql_like(params.query))
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