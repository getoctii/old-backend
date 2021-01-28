local validate = require 'lapis.validate'
local Channels = require 'models.channels'
local helpers = require 'lapis.application'
local contains = require 'array'.includes
local map = require 'array'.map
local Users = require 'models.users'
local broadcast = require 'util.broadcast'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'

local Typing = {}

function Typing:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })

  if not channel.community_id then
    helpers.assert_error(contains(map(channel:get_conversation():get_participants(), function(participant)
      return participant.user_id
    end), self.user.id), { 403, 'MissingPermissions' })
  else
    local member = helpers.assert_error(MembersModel:find({
      community_id = channel.community_id,
      user_id = self.user.id
    }), { 404, 'ChannelNotFound' })
    helpers.assert_error(engine.has_community_permissions(member, { GroupsModel.permissions.SEND_MESSAGES }), { 403, 'MissingPermissions' })
  end

  local user = assert(Users:find({ id = self.user.id }))

  broadcast('channel:' .. channel.id, 'TYPING', {
    channel_id = channel.id,
    user_id = user.id,
    username = user.username
  })

  return {
    status = 204
  }
end

return Typing