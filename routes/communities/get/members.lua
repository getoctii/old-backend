local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local Communities = require 'models.communities'
local preload = require 'lapis.db.model'.preload

local map = require 'util.map'
local contains = require 'util.contains'
local empty = require 'util.empty'
local json = require 'cjson'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' }}
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

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