local Users = require 'models.users'
local helpers = require 'lapis.application'
local preload = require 'lapis.db.model'.preload
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local json = require 'cjson'
local empty = require 'array'.is_empty

local Mentions = {}

function Mentions:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'InvalidUser' })

  local raw_mentions = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' }):get_mentions()
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