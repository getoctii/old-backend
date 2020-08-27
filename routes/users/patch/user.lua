local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Users = require 'models.users'
local argon2 = require 'argon2'
local rand = require 'openssl.rand'
local encoding = require 'lapis.util.encoding'
local empty = require 'util.empty'
local generateDiscriminator = require 'util.generatediscriminator'
local http = require 'resty.http'

return function(self)
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' },
    { 'oldPassword', exists = true, optional = true, min_length = 8, max_length = 128, 'InvalidPassword' },
    { 'newPassword', exists = true, optional = true, min_length = 8, max_length = 128, 400, 'InvalidPassword' },
    { 'username', exists = true, optional = true, min_length = 3, max_length = 16, matches_pattern = '^%a+$', 'InvalidUsername' },
    { 'avatar', exists = true, optional = true, matches_regexp = '^https:\\/\\/file\\.coffee\\/u\\/[a-zA-Z0-9_-]{7,14}\\.(png|jpeg|jpg)$', 'InvalidAvatar' }
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
    patch.discriminator = generateDiscriminator(self.params.username)
  end

  if self.params.avatar then
    local httpc = assert(http.new())
    local status = assert(httpc:request_uri(self.params.avatar, { method = 'HEAD' })).status

    helpers.assert_error(status == 200, { 400, 'InvalidAvatar' })
    patch.avatar = self.params.avatar
  end

  helpers.assert_error(not empty(patch), { 400, 'InvalidPatch'})
  user:update(patch)

  return {
    status = 201,
    layout = false
  }
end
