local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Channels = require 'models.channels'
local empty = require 'util.empty'
local http = require 'resty.http'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'name', exists = true, optional = true, matches_regexp = '^[a-zA-Z0-9_\\-]+$', min_length = 2, max_length = 30, 'ChannelNameInvalid' },
    { 'description', exists = true, optional = true, max_length = 140, 'InvalidDescription' },
    { 'color', exists = true, optional = true, is_color = true, 'InvalidColor' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelsNotFound' })
  if not channel.community_id then
    helpers.yield_error({ 400, 'InvalidChannel' })
  else
    helpers.assert_error(channel:get_community().owner_id == self.user_id, { 403, 'MissingPermissions' })
  end

  local patch = {}

  if self.params.name then
    patch.name = self.params.name
  end

  if self.params.description then
    patch.description = self.params.description
  end

  if self.params.color then
    patch.color = self.params.color
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch' })
  channel:update(patch)

  return {
    status = 204,
    layout = false
  }
end
