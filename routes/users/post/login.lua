local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local Users = require 'models.users'

local argon2 = require 'argon2'
local generateLoginToken = require 'util.jwt'

return function(self)
  validate.assert_valid(self.params, {
    { 'email', exists = true, min_length = 3, max_length = 128, matches_pattern = '^[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?$', { 400, 'InvalidEmail' }},
    { 'password', exists = true, min_length = 8, max_length = 128, { 400, 'InvalidPassword' }}
  })

  local user = helpers.assert_error(Users:find({ email = self.params.email }), { 404, 'UserNotFound' })
  helpers.assert_error(argon2.verify(user.password, self.params.password), { 401, 'WrongPassword' })

  return {
    json = {
      authorization = generateLoginToken(user.id)
    }
  }
end
