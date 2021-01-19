local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Users = require 'models.users'
local argon2 = require 'argon2'
local rand = require 'openssl.rand'
local encoding = require 'lapis.util.encoding'
local empty = require 'array'.is_empty
local generateDiscriminator = require 'util.generatediscriminator'
local http = require 'resty.http'
local map = require 'array'.map
local broadcast_multiple = require 'util.broadcast_multiple'
local generate_grip_channels = require 'util.generate_grip_channels'

local User = {}

function User:GET()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID'}
  })

  local user = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' })

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
    color = user.color
  }

  if (not user.last_ping) or ((os.time() - user.last_ping) > 180) then
    info.state = 'offline'
  end

  if user.id == self.user_id then
    info.email = user.email
  end

  return {
    json = info
  }
end

function User:PATCH()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'oldPassword', exists = true, optional = true, min_length = 8, max_length = 128, 'InvalidPassword' },
    { 'newPassword', exists = true, optional = true, min_length = 8, max_length = 128, 400, 'InvalidPassword' },
    { 'username', exists = true, optional = true, min_length = 3, max_length = 16, matches_pattern = '^%a+$', 'InvalidUsername' },
    { 'avatar', exists = true, optional = true, matches_regexp = '^https:\\/\\/file\\.coffee\\/u\\/[a-zA-Z0-9_-]{7,14}\\.(png|jpeg|jpg|gif)$', 'InvalidAvatar' },
    { 'status', exists = true, optional = true, max_length = 140, 'InvalidStatus' },
    { 'state', exists = true, optional = true, one_of = {
      'offline',
      'idle',
      'dnd',
      'online',
    }, 'InvalidState'},
    { 'color', exists = true, optional = true, is_color = true, 'InvalidColor' }
  })

  helpers.assert_error(self.params.id == self.user_id, { 403, 'MissingPermissions' })
  local user = helpers.assert_error(Users:find({ id = self.params.id }), { 404, 'UserNotFound' })

  local patch = {}

  if self.params.oldPassword and self.params.newPassword then
    helpers.assert_error(argon2.verify(user.password, self.params.oldPassword), { 401, 'WrongPassword' })
    local salt = encoding.encode_base64(assert(rand.bytes(32)))
    patch.password = assert(argon2.hash_encoded(self.params.newPassword, salt, {
      variant = argon2.variants.argon2_id,
      parallelism = 2,
      m_cost = 2 ^ 18,
      t_cost = 8
    }))
  end

  if self.params.username then
    patch.username = self.params.username
    if user.discriminator ~= 0 then
      patch.discriminator = generateDiscriminator(self.params.username)
    end
  end

  if self.params.avatar then
    local httpc = assert(http.new())
    local status = assert(httpc:request_uri(self.params.avatar, { method = 'HEAD' })).status

    helpers.assert_error(status == 200, { 400, 'InvalidAvatar' })
    patch.avatar = self.params.avatar
  end

  if self.params.status then
    patch.status = self.params.status
  end

  if self.params.state then
    patch.state = Users.states:for_db(self.params.state)
  end

  if self.params.color then
    patch.color = self.params.color
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