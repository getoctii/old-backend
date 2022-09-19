local Users = require 'models.users'
local helpers = require 'lapis.application'
local preload = require 'lapis.db.model'.preload
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local json = require 'cjson'

local map = require 'array'.map
local empty = require 'array'.is_empty

local Members = {}

function Members:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local members = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' }):get_members()
  preload(members, 'community')

  local memberStubs = map(members, function(row)
    local community = row:get_community()
    return {
      id = row.id,
      community = {
        id = community.id,
        icon = community.icon,
        name = community.name,
        large = community.large,
        owner_id = community.owner_id
      }
    }
  end)

  if empty(memberStubs) then
    memberStubs = json.empty_array
  end

  return {
    json = memberStubs
  }
end

return Members