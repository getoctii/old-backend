local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Channels = require 'models.channels'
local contains = require 'array'.includes
local map = require 'array'.map
local db = require 'lapis.db'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'

local Reorder = {}

function Reorder:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.type == 2, { 400, 'ChannelNotCategory' })
  helpers.assert_error(channel.community_id, { 400, 'CommunityNotFound' })
  
  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.READ_MESSAGES })), { 403, 'MissingPermissions' })


  return {
    layout = false,
    status = 204
  }
end

return Reorder