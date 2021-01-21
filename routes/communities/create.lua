local Communities = require 'models.communities'
local Members = require 'models.members'
local validate = require 'lapis.validate'
local resubscribe = require 'util.resubscribe'
local broadcast = require 'util.broadcast'
local http = require 'resty.http'
local helpers = require 'lapis.application'
local uuid = require 'util.uuid'

local Create = {}

function Create:POST()
  validate.assert_valid(self.params, {
    { 'name', exists = true, min_length = 2, max_length = 16, 'CommunityNameInvalid' },
    { 'icon', exists = true, matches_regexp = '^https:\\/\\/file\\.coffee\\/u\\/[a-zA-Z0-9_-]{7,14}\\.(png|jpeg|jpg|gif)$', 'InvalidIcon' }
  })

  local httpc = assert(http.new())
  local status = assert(httpc:request_uri(self.params.icon, { method = 'HEAD' })).status

  helpers.assert_error(status == 200, { 400, 'InvalidIcon' })

  local community = assert(Communities:create({ -- TODO: handle all db errors
    id = assert(uuid()),
    name = self.params.name, -- TODO: Differenciate between query params and form
    icon = self.params.icon,
    large = true,
    owner_id = self.user.id
  }))

  local member = assert(Members:create({
    id = assert(uuid()),
    user_id = self.user.id, -- TODO: check that acc exists
    community_id = community.id
  }))

  broadcast('user:' .. self.user.id, 'NEW_MEMBER', {
    id = member.id,
    community = {
      id = community.id,
      icon = community.icon,
      name = community.name,
      large = community.large,
      owner_id = community.owner_id
    }
  })

  resubscribe('user:' .. self.user.id)

  broadcast('community:' .. community.id, 'JOIN_MEMBER', {
    id = member.id,
    community_id = community.id,
    user_id = self.user.id
  })

  return {
    json = {
      id = community.id,
      name = community.name,
      icon = community.icon,
      large = community.large,
      owner_id = community.owner_id
    }
  }
end

return Create