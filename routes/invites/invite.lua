local helpers = require 'lapis.application'
local Invites = require 'models.invites'
local db = require 'lapis.db'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local MembersModel = require 'models.members'
local Set = require 'pl.Set'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Invite = {}

function Invite:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local invite = helpers.assert_error(Invites:find({ id = params.id }), 'InviteNotFound')
  local member = helpers.assert_error(MembersModel:find({
    community_id =   invite.community_id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })

  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_INVITES })), { 403, 'MissingPermissions' })

  return {
    json = {
      id = invite.id,
      code = invite.code,
      author_id = invite.author_id,
      created_at = invite.created_at,
      updated_at = invite.updated_at,
      uses = invite.uses,
      community = invite.community_id
    }
  }
end

function Invite:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local invite = helpers.assert_error(Invites:find({ id = params.id }), 'InviteNotFound')

  local member = helpers.assert_error(MembersModel:find({
    community_id = invite.community_id,
    user_id = self.user.id
  }), { 404, 'InviteNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_INVITES })), { 403, 'MissingPermissions' })

  assert(db.delete('invites', {
    id = invite.id
  }))

  return {
    layout = false
  }
end

return Invite