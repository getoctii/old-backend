local Communities = require 'models.communities'
local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local db = require 'lapis.db'
local preload = require 'lapis.db.model'.preload
local helpers = require 'lapis.application'
local Members = require 'models.members'
local broadcast = require 'util.broadcast'

local inspect = require 'inspect'

local uuid = require 'util.uuid'
local map = require 'util.map'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })
  -- TODO: NOT ATOMIC BUT OK
  local community = helpers.assert_error(Communities:find({ id = self.params.id }), 'CommunityNotFound')
  helpers.assert_error(community.owner_id == self.user_id, { 403, 'MissingPermissions' })
  preload(community, 'members')

  for _, row in ipairs(community:get_members()) do
    broadcast('user:' .. row.user_id, 'DELETED_MEMBER', {
      id = row.id
    })
  end

  assert(db.delete('communities', {
    id = self.params.id
  }))
  -- community:delete() TODO: Causes error, let's file an issue.
  assert(db.delete('members', 'community_id = ?', self.params.id))
  assert(db.delete('channels', 'community_id = ?', self.params.id))
  -- TODO: Delete messages as well.

  -- TODO: Inefficient, but /shrug

  return { layout = false }
end