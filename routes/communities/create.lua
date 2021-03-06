local Communities = require 'models.communities'
local Members = require 'models.members'
local resubscribe = require 'util.resubscribe'
local broadcast = require 'util.broadcast'
local http = require 'resty.http'
local helpers = require 'lapis.application'
local uuid = require 'util.uuid'
local Groups = require 'models.groups'
local db = require 'lapis.db'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Create = {}

function Create:POST()
  local params = validate(self.params, types.shape {
    name = custom_types.community_name,
    icon = custom_types.image
  })

  local httpc = assert(http.new())
  local status = assert(httpc:request_uri(params.icon, { method = 'HEAD' })).status

  helpers.assert_error(status == 200, { 400, 'InvalidIcon' })

  local community = assert(Communities:create({ -- TODO: handle all db errors
    id = assert(uuid()),
    name = params.name, -- TODO: Differenciate between query params and form
    icon = params.icon,
    large = true,
    owner_id = self.user.id,
    base_permissions = db.array({ Groups.permissions.READ_MESSAGES, Groups.permissions.SEND_MESSAGES })
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