local Users = require 'models.users'
local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local preload = require 'lapis.db.model'.preload

local json = require 'cjson'

local map = require 'array'.map
local empty = require 'array'.is_empty

local Members = {}

function Members:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.params.id == self.user_id, { 403, 'InvalidUser' })

  local members = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' }):get_members()
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