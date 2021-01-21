local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local Communities = require 'models.communities'
local preload = require 'lapis.db.model'.preload

local map = require 'array'.map
local contains = require 'array'.includes
local empty = require 'array'.is_empty
local json = require 'cjson'

local Members = {}

function Members:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })
  helpers.assert_error(contains(map(community:get_members(), function(member)
    return member.user_id
  end), self.user.id), { 403, 'MissingPermissions' })

  local pager = community:get_members_paginated({
    per_page = 25,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  local page = pager:get_page(self.params.created_at)
  preload(page, 'user')

  local members = map(page, function(row)
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

return Members