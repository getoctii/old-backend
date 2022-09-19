local encode_json = require 'pgmoon.json'.encode_json
local validate = require 'util.validate'
local ResourcesModel = require 'models.resources'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
local uuid = require 'util.uuid'
local MembersModel = require 'models.members'
local engine = require 'util.permissions.engine'
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'
local tablex = require 'pl.tablex'
local json = require 'cjson'

local theme_type = types.shape {
  colors = types.shape {
    primary = types.string,
    secondary = types.string,
    success = types.string,
    info = types.string,
    danger = types.string,
    warning = types.string,
    light = types.string,
    dark = types.string,
  },
  text = types.shape {
    normal = types.string,
    inverse = types.string,
    primary = types.string,
    danger = types.string,
    warning = types.string,
    secondary = types.string,
  },
  backgrounds = types.shape {
    primary = types.string,
    secondary = types.string,
  },
  settings = types.shape {
    background = types.string,
    card = types.string,
    input = types.string,
  },
  sidebar = types.shape {
    background = types.string,
    seperator = types.string,
    shadow = types.string,
  },
  context = types.shape {
    background = types.string,
    seperator = types.string,
  },
  channels = types.shape {
    background = types.string,
    seperator = types.string,
  },
  chat = types.shape {
    background = types.string,
    hover = types.string,
  },
  status = types.shape {
    selected = types.string,
    online = types.string,
    idle = types.string,
    dnd = types.string,
    offline = types.string,
  },
  message = types.shape {
    author = types.string,
    date = types.string,
    message = types.string,
  },
  mention = types.shape {
    me = types.string,
    other = types.string,
  },
  input = types.shape {
    background = types.string,
    text = types.string,
  },
  modal = types.shape {
    background = types.string,
    foreground = types.string,
  },
  emojis = types.shape {
    background = types.string,
    input = types.string,
  },
  global = types.string:is_optional()
}

local theme_bundle_type = types.shape {
  name = types.string,
  dark = theme_type,
  light = theme_type
}

local server_integration_type = types.shape {
  token = custom_types.null:is_optional()
}

local Payload = {}

function Payload:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = resource:get_product().organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  if resource.payload == db.NULL then
    return {
      status = 404,
      layout = false
    }
  end

  return {
    json = resource.payload
  }
end

function Payload:PUT()
  local params = validate({
    id = self.params.id,
    resource_id = self.params.resource_id
  }, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })
  local member = helpers.assert_error(MembersModel:find({
    community_id = resource:get_product().organization_id,
    user_id = self.user.id
  }), { 403, 'MissingPermissions' })
  helpers.assert_error(engine.has_community_permissions(member, Set({ GroupsModel.permissions.MANAGE_PRODUCTS })), { 403, 'MissingPermissions' })

  local tmp = tablex.copy(self.params)
  tmp.id = nil
  tmp.resource_id = nil
  local payload

  if resource.type == ResourcesModel.types.THEME then
    payload = validate(tmp, theme_bundle_type)

    if not resource.payload then
      payload.id = uuid()
    else
      payload.id = resource.payload.id
    end
  elseif resource.type == ResourcesModel.types.SERVER_INTEGRATION then
    payload = validate(tmp, server_integration_type)

    if payload.token == json.null or not resource.payload then
      payload.token = uuid()
    else
      payload.token = resource.payload.token
    end
  else
    return {
      status = 400,
      json = {
        errors = {'NotImplmented'}
      },
      layout = false
    }
  end

  resource:update({
    payload = db.raw(encode_json(payload))
  })

  return {
    status = 200,
    layout = false
  }
end

return Payload