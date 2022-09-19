local types = require 'tableshape'.types
local uuid = require 'resty.jit-uuid'
local email = require 'util.email'
local C = require 'pl.comprehension'.new()
local Set = require 'pl.Set'
local GroupsModel = require 'models.groups'
local ResourcesModel = require 'models.resources'
local json = require 'cjson'

local function regexp(regex)
  return types.custom(function(value)
    if not types.string(value) then return nil, 'Expected string' end

    if ngx.re.match(value, regex, 'i') then
      return true
    else
      return nil, 'Does not match regexp'
    end
  end)
end

local uuid_type = types.custom(function(value)
  if not types.string(value) then return nil, 'Expected string' end

  if uuid.is_valid(value) then
    return true
  else
    return nil, 'Expected valid UUID'
  end
end)

local function new_set(x)
  return Set(x)
end

local keypair = types.shape {
  privateKey = types.array_of(types.integer / tonumber),
  publicKey = types.array_of(types.integer / tonumber),
  salt = types.array_of(types.integer / tonumber),
  iv = types.array_of(types.integer / tonumber)
}

local hex = '[a-fA-f0-9]'
local three = '^#' .. table.concat({ hex, hex, hex }, '') .. '$'
local six = '^#' .. table.concat({ hex, hex, hex, hex, hex, hex }, '') .. '$'

return {
  username = types.string:length(3, 16) * types.pattern('^%w+$'),
  group_name = types.string:length(2, 30),
  community_name = types.string:length(2, 30),
  channel_name = types.string:length(2, 30) * regexp('^[a-zA-Z0-9_\\-]+$'),
  discriminator = types.range(0, 9999),
  email = types.string:length(3, 128) * regexp(email),
  password = types.string:length(8, 128),
  regexp = regexp,
  uuid = uuid_type,
  image = regexp('^https:\\/\\/cdn\\.octii.chat\\/icons\\/.+\\/.+$'),
  color = types.pattern(three) + types.pattern(six),
  permissions = types.array_of(types.one_of(C 'x for x=1,18' () )) / new_set,
  overrides = types.array_of(types.one_of({
    GroupsModel.permissions.READ_MESSAGES,
    GroupsModel.permissions.SEND_MESSAGES,
    GroupsModel.permissions.EMBED_LINKS,
    GroupsModel.permissions.MENTION_MEMBERS,
    GroupsModel.permissions.MENTION_GROUPS,
    GroupsModel.permissions.MENTION_EVERYONE,
    GroupsModel.permissions.MENTION_SOMEONE,
    GroupsModel.permissions.MANAGE_MESSAGES
  })) / new_set,
  null = types.literal(json.null),
  resource_type = types.one_of({
    ResourcesModel.types.THEME,
    ResourcesModel.types.CLIENT_INTEGRATION,
    ResourcesModel.types.SERVER_INTEGRATION
  }),
  keychain = types.shape {
    encryption = keypair,
    signing = keypair,
    tokenSalt = types.array_of(types.integer / tonumber)
  },
  encrypted_message = types.shape {
    data = types.array_of(types.integer / tonumber),
    signature = types.array_of(types.integer / tonumber),
    key = types.array_of(types.integer / tonumber),
    iv = types.array_of(types.integer / tonumber)
  }
}