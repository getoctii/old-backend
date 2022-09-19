local helpers = require 'lapis.application'
local Users = require 'models.users'
local argon2 = require 'argon2'
local rand = require 'openssl.rand'
local encoding = require 'lapis.util.encoding'
local empty = require 'array'.is_empty
local generateDiscriminator = require 'util.generatediscriminator'
local http = require 'resty.http'
local map = require 'array'.map
-- local broadcast_multiple = require 'util.broadcast_multiple'
-- local generate_grip_channels = require 'util.generate_grip_channels'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local User = {}

function User:GET()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  local user = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' })
  local info = {
    id = user.id,
    username = user.username,
    avatar = user.avatar,
    discriminator = user.discriminator,
    status = user.status,
    state = Users.states:to_name(user.state),
    badges = map(user.badges, function(badge)
      return Users.badges:to_name(badge)
    end),
    color = user.color,
    disabled = user.disabled,
    plus = user.plus
  }

  if (not user.last_ping) or ((os.time() - user.last_ping) > 180) then
    info.state = 'offline'
  end

  if user.id == self.user.id or self.user.discriminator == 0 then
    info.email = user.email
    info.developer = user.developer
    info.totp = not not user.totp_key
  end

  return {
    json = info
  }
end

function User:PATCH()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid,
    oldPassword = custom_types.password:is_optional(),
    newPassword = custom_types.password:is_optional(),
    username = custom_types.username:is_optional(),
    avatar = custom_types.image:is_optional(),
    status = types.string:length(0, 140):is_optional(),
    state = types.one_of({ 'online', 'idle', 'dnd', 'offline' }):is_optional(),
    color = custom_types.color:is_optional(),
    developer = types.literal(true):is_optional()
  })

  helpers.assert_error(params.id == self.user.id, { 403, 'MissingPermissions' })
  local user = helpers.assert_error(Users:find({ id = params.id }), { 404, 'UserNotFound' })

  local patch = {}

  if params.oldPassword and params.newPassword then
    helpers.assert_error(argon2.verify(user.password, params.oldPassword), { 401, 'WrongPassword' })
    local salt = encoding.encode_base64(assert(rand.bytes(32)))
    patch.password = assert(argon2.hash_encoded(params.newPassword, salt, {
      variant = argon2.variants.argon2_id,
      parallelism = 2,
      m_cost = 2 ^ 18,
      t_cost = 8
    }))
  end

  if params.username then
    patch.username = params.username
    if user.discriminator ~= 0 then
      patch.discriminator = generateDiscriminator(params.username)
    end
  end

  if params.avatar then
    local httpc = assert(http.new())
    local status = assert(httpc:request_uri(params.avatar, { method = 'HEAD' })).status

    helpers.assert_error(status == 200, { 400, 'InvalidAvatar' })
    patch.avatar = params.avatar
  end

  if params.status then
    patch.status = params.status
  end

  if params.state then
    patch.state = Users.states:for_db(params.state)
  end

  if params.color then
    patch.color = params.color
  end

  if params.developer then
    patch.developer = params.developer
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch'})
  user:update(patch)
  -- TODO: Contact pushpin about efficently pushing to multiple channels
  -- user:refresh()

  -- local user_payload = {
  --   id = user.id,
  --   username = user.username,
  --   avatar = user.avatar,
  --   discriminator = user.discriminator,
  --   status = user.status,
  --   state = Users.states:to_name(user.state),
  --   badges = map(user.badges, function(badge)
  --     return Users.badges:to_name(badge)
  --   end),
  --   color = user.color
  -- }

  -- if (not user.last_ping) or ((os.time() - user.last_ping) > 180) then
  --   user_payload.state = 'offline'
  -- end

  -- broadcast_multiple(generate_grip_channels(user), 'UPDATED_USER', user_payload)

  return {
    status = 204,
    layout = false
  }
end

return User