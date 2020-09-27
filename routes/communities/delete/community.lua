local Communities = require 'models.communities'
local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local db = require 'lapis.db'
local helpers = require 'lapis.application'
local Members = require 'models.members'

local inspect = require 'inspect'

local uuid = require 'util.uuid'
local map = require 'util.map'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })

  local community = helpers.assert_error(Communities:find({ id = self.params.id }), 'CommunityNotFound')
  helpers.assert_error(community.owner_id == self.user_id, { 403, 'MissingPermissions' })

  assert(community:delete())
  assert(db.delete('members', 'community_id = ?', self.params.id))
  assert(db.delete('channels', 'community_id = ?', self.params.id))
  -- TODO: Delete messages as well.
  return { layout = false }
end