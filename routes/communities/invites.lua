local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Communities = require 'models.communities'
local map = require 'array'.map
local empty = require 'array'.is_empty
local json = require 'cjson'
local InvitesModel = require 'models.invites'
local uuid = require 'util.uuid'
local MembersModel = require 'models.members'
local GroupsModel = require 'models.groups'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local nanoid = require 'nanoid'

local Invites = {}

function Invites:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_INVITES })), { 403, 'MissingPermissions' })

  local invites = map(community:get_invites(), function(row)
    return {
      id = row.id,
      code = row.code,
      author_id = row.author_id,
      created_at = row.created_at,
      updated_at = row.updated_at,
      uses = row.uses
    }
  end)

  if empty(invites) then
    invites = json.empty_array
  end

  return {
    json = invites
  }
end

function Invites:POST()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), { 404, 'CommunityNotFound' })

  local member = helpers.assert_error(MembersModel:find({
    community_id = community.id,
    user_id = self.user.id
  }), { 404, 'CommunityNotFound' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.CREATE_INVITES })), { 403, 'MissingPermissions' })

  local invite = InvitesModel:create({
    id = uuid(),
    code = nanoid(10),
    community_id = self.params.id,
    author_id = self.user.id,
    uses = 0
  })

  return {
    json = {
      id = invite.id,
      code = invite.code,
      created_at = invite.created_at,
      updated_at = invite.updated_at
    }
  }
end

return Invites