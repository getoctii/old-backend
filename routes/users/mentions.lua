local Users = require 'models.users'
local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local preload = require 'lapis.db.model'.preload

local json = require 'cjson'
local empty = require 'array'.is_empty
local reduce = require 'array'.reduce

local Mentions = {}

function Mentions:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  helpers.assert_error(self.params.id == self.user.id, { 403, 'InvalidUser' })

  local raw_mentions = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' }):get_mentions()
  preload({ mentions = 'message' })

  local mentions = {}
  for _, row in ipairs(raw_mentions) do
    local channel_id = (row:get_message() or {}).channel_id
    if channel_id then
      if not mentions[channel_id] then mentions[channel_id] = {} end
      table.insert(mentions[channel_id], {
        id = row.id,
        message_id = row.message_id,
        read = row.read
      })
    end
  end

  return {
    json = empty(mentions) and json.empty_array or mentions
  }
end

return Mentions