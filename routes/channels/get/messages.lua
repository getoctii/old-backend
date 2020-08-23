local helpers = require 'lapis.application'
local validate = require 'lapis.validate'
local Channels = require 'models.channels'
local preload = require 'lapis.db.model'.preload

local map = require 'util.map'
local empty = require 'util.empty'
local json = require 'cjson'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, { 400, 'InvalidUUID' }}
  })
  print(self.params.created_at)
  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })

  local pager = channel:get_messages_paginated({
    per_page = 25,
    ordered = {
      'created_at'
    },
    order = 'desc'
  })

  local page = pager:get_page(self.params.created_at)
  preload(page, 'author')

  local messages = map(page, function(row)
    local author = row:get_author()
    return {
      id = row.id,
      author = {
        id = author.id,
        username = author.username,
        avatar = author.avatar,
        discriminator = author.discriminator
      },
      created_at = row.created_at,
      updated_at = row.updated_at,
      content = row.content
    }
  end)

  if empty(messages) then
    messages = json.empty_array
  end

  return {
    json = messages
  }
end