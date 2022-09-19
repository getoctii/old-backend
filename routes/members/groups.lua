local GroupsModel = require 'models.groups'
local MembersModel = require 'models.members'
local GroupMembersModel = require 'models.group_members'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
local broadcast = require 'util.broadcast'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local resubscribe = require 'util.resubscribe'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Groups = {}

function Groups:POST()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    group_id = custom_types.uuid
  })

  local member = helpers.assert_error(MembersModel:find(params.id), { 404, 'MemberNotFound' })
  local community = member:get_community()
  local group = helpers.assert_error(GroupsModel:find(params.group_id), { 404, 'GroupNotFound'})
  helpers.assert_error(group.community_id == community.id, { 404, 'GroupNotFound' })

  local current_member = helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'MemberNotFound' })
  helpers.assert_error(engine.has_community_permissions(current_member, Set({ GroupsModel.permissions.MANAGE_GROUPS })), { 403, 'MissingPermissions' })


  GroupMembersModel:create({
    member_id = member.id,
    group_id = params.group_id
  })

  broadcast('community:' .. community.id, 'NEW_GROUP_MEMBER', {
    member_id = member.id,
    user_id = member.user_id,
    group_id = params.group_id,
    community_id = community.id
  })

  resubscribe('user:' .. member.user_id)

  return {
    status = 204,
    layout = false
  }
end

function Groups:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    group_id = custom_types.uuid
  })

  local member = helpers.assert_error(MembersModel:find(params.id), { 404, 'MemberNotFound' })
  local community = member:get_community()
  local group = helpers.assert_error(GroupsModel:find(params.group_id), { 404, 'GroupNotFound'})
  helpers.assert_error(group.community_id == community.id, { 404, 'GroupNotFound' })

  local current_member = helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'MemberNotFound' })
  helpers.assert_error(engine.has_community_permissions(current_member, Set({ GroupsModel.permissions.MANAGE_GROUPS })), { 403, 'MissingPermissions' })

  db.delete('group_members', { member_id = member.id, group_id = params.group_id })

  broadcast('community:' .. community.id, 'DELETED_GROUP_MEMBER', {
    member_id = member.id,
    user_id = member.user_id,
    group_id = params.group_id,
    community_id = community.id
  })

  resubscribe('user:' .. member.user_id)

  return {
    status = 204,
    layout = false
  }
end

return Groups