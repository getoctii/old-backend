local validate = require 'lapis.validate'
local OverridesModel = require 'models.overrides'
local helpers = require 'lapis.application'
local Channels = require 'models.channels'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local C = require 'pl.comprehension'.new()
local array = require 'array'
local db = require 'lapis.db'
local MembersModel = require 'models.members'

local permission_set = Set(C 'x for x=1,17' ())

local Overrides = {}

function Overrides:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'group_id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'allow', exists = true, is_array = true, 'InvalidAllow' },
    { 'deny', exists = true, is_array = true, 'InvalidDeny' }
  })

  helpers.assert_error(type((self.params.allow) == 'table') and ((Set(self.params.allow) + permission_set) == permission_set), { 400, 'InvalidAllow' })
  helpers.assert_error(type((self.params.deny) == 'table') and ((Set(self.params.deny) + permission_set) == permission_set), { 400, 'InvalidDeny' })

  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), { 404, 'ChannelNotFound' })
  helpers.assert_error(channel.community_id, { 404, 'ChannelNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = channel.community_id,
    user_id = self.user.id
  }), { 404, 'ChannelNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_CHANNELS })))

  OverridesModel:create({
    channel_id = self.params.id,
    group_id = self.params.group_id,
    allow = array.empty(self.params.permissions) and db.raw('array[]::integer[]') or db.array(Set.values(Set(self.params.allow))),
    deny = array.empty(self.params.permissions) and db.raw('array[]::integer[]') or db.array(Set.values(Set(self.params.deny)))
  })

  return {
    status = 204,
    layout = false
  }
end

return Overrides