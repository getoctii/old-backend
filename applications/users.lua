local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local helpers = require 'lapis.application'
local Users = require 'models.users'
local jwt = require 'resty.jwt'
local inspect = require 'inspect' -- snip snooop

local rand = require 'openssl.rand'
local argon2 = require 'argon2'
local uuid = require 'util.uuid'

return function(app)
  app:post('/users', helpers.capture_errors_json(function(self)
    self.res.headers["Access-Control-Allow-Origin"] = "*"
    print(inspect(self.params))
    validate.assert_valid(self.params, {
      { 'username', exists = true, min_length = 3, max_length = 16, matches_pattern = '^%a+$', 'InvalidUsername' },
      { 'password', exists = true, min_length = 8, max_length = 128, 'InvalidPassword' },
      { 'email', exists = true, min_length = 3, max_length = 128, 'InvalidEmail' }
    })

    local salt = encoding.encode_base64(assert(rand.bytes(32))) -- 256 bit salt because we paranoid bois
    local hashed = assert(argon2.hash_encoded(self.params.password, salt, {
      variant = argon2.variants.argon2_id,
      parallelism = 2,
      m_cost = 2 ^ 18,
      t_cost = 8
    }))

    local user = Users:create({
      username = self.params.username,
      password = hashed,
      email = self.params.email,
      id = assert(uuid()),
      avatar = 'https://cdn.nekos.life/avatar/avatar_48.png',
      discriminator = 6969
    })

    return {
      status = 201,
      json = {
        id = user.id,
        username = user.username,
        avatar = user.avatar,
        discriminator = user.discriminator
      }
    }
  end))

  app:post('/users/login', helpers.capture_errors_json(function(self)
    print(inspect(self.params))
    self.res.headers["Access-Control-Allow-Origin"] = "*"
    validate.assert_valid(self.params, {
      { 'email', exists = true, min_length = 3, max_length = 128, matches_pattern = '^%a+', 'InvalidEmail' },
      { 'password', exists = true, min_length = 8, max_length = 128, 'InvalidPassword' }
    })


    local user = Users:find({ email = self.params.email })
    if not user then
      helpers.yield_error('NotFound')
    end

    local ok, err = argon2.verify(user.password, self.params.password)
    if ok and not err then
      return {
        json = {
          authorization = true,
          id = user.id,
          username = user.username,
          avatar = user.avatar,
          discriminator = user.discriminator
        }
      }
    else
      helpers.yield_error('WrongPassword')
    end
  end))

  app:get('/users/:id', helpers.capture_errors_json(function(self)
    self.res.headers["Access-Control-Allow-Origin"] = "*"
    validate.assert_valid(self.params, {}) -- TODO: Validate UUID

    local user = Users:find({ id = self.params.id })
    if not user then
      helpers.yield_error('NotFound')
    end

    return {
      json = {
        id = user.id,
        username = user.username,
        avatar = user.avatar,
        discriminator = user.discriminator
      }
    }
  end))
end