local GroupsModel = require 'models.groups'
local MembersModel = require 'models.members'
local GroupMembersModel = require 'models.group_members'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
local validate = require 'lapis.validate'
local broadcast = require 'util.broadcast'
local engine = require 'util.permissions.engine'

local Groups = {}

function Groups:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'group_id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local member = helpers.assert_error(MembersModel:find(self.params.id), { 404, 'MemberNotFound' })
  local community = member:get_community()
  local group = helpers.assert_error(GroupsModel:find(self.params.group_id), { 404, 'GroupNotFound'})
  helpers.assert_error(group.community_id == community.id, { 404, 'GroupNotFound' })

  helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'MemberNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, { Groups.permissions.MANAGE_PERMISSIONS }), { 403, 'MissingPermissions' })


  GroupMembersModel:create({
    member_id = member.id,
    group_id = self.params.group_id
  })

  broadcast('community:' .. community.id, 'NEW_GROUP_MEMBER', {
    member_id = member.id,
    group_id = self.params.group_id,
    community_id = community.id
  })

  return {
    status = 204,
    layout = false
  }
end

function Groups:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'group_id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local member = helpers.assert_error(MembersModel:find(self.params.id), { 404, 'MemberNotFound' })
  local community = member:get_community()
  local group = helpers.assert_error(GroupsModel:find(self.params.group_id), { 404, 'GroupNotFound'})
  helpers.assert_error(group.community_id == community.id, { 404, 'GroupNotFound' })

  helpers.assert_error(MembersModel:find({
    community_id = group.community_id,
    user_id = self.user.id
  }), { 404, 'MemberNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, { GroupsModel.permissions.MANAGE_PERMISSIONS }), { 403, 'MissingPermissions' })

  db.delete('group_members', { member_id = member.id, group_id = self.params.group_id })

  broadcast('community:' .. community.id, 'DELETED_GROUP_MEMBER', {
    member_id = member.id,
    group_id = self.params.group_id,
    community_id = community.id
  })

  return {
    status = 204,
    layout = false
  }
end

return Groups