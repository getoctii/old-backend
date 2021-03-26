local encode_json = require 'pgmoon.json'.encode_json
local validate = require 'util.validate'
local ResourcesModel = require 'models.resources'
local types = require 'tableshape'.types
local custom_types = require 'util.types'
local helpers = require 'lapis.application'
local db = require 'lapis.db'
local uuid = require 'util.uuid'

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

local Payload = {}

function Payload:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })

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
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    resource_id = custom_types.uuid,
    payload = theme_bundle_type
  })

  local resource = helpers.assert_error(ResourcesModel:find(params.resource_id), { 404, 'ResourceNotFound' })

  params.payload.id = uuid()

  resource:update({
    payload = db.raw(encode_json(params.payload))
  })

  return {
    status = 200,
    layout = false
  }
end

return Payload