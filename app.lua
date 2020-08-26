package.path = package.path .. ';./?/init.lua'
local lapis = require 'lapis'
local config = require 'lapis.config'.get()

local jwt = require 'resty.jwt'
local inspect = require 'inspect'
local validators = require 'resty.jwt-validators'
local helpers = require 'lapis.application'
local mm = require 'mm'

local app = lapis.Application()

-- Validators
require 'util.validators.uuid'

-- Routes
require('routes.users')(app)
require('routes.channels')(app)
-- require('routes.communities')(app)
require('routes.events')(app)
-- require('routes.messages')(app)
require('routes.conversations')(app)


-- TODO: Implement OPTION routes

-- Middleware
app:before_filter(function(self)
  self.res.headers['Access-Control-Allow-Origin'] = '*'
  self.res.headers['Access-Control-Allow-Methods'] = '*' -- owo, maybe * _breaks things_ maybe define the methods manually
  self.res.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'
  self.res.headers['owo'] = 'suckmycock'

  if self.req.method == 'OPTIONS' then
    self:write({
      status = 203
    })
    return
  end

  if self.route_name ~= 'users.post.login' and self.route_name ~= 'users.post.register' then
    local token = jwt:verify(config.public_key, self.req.headers.Authorization or self.params.authorization, {
      iss = validators.equals('chat.innatical.com'),
      aud = validators.equals('chat.innatical.com'),
      nbf = validators.is_not_before(),
      exp = validators.is_not_expired()
    })

    if token.verified == true then
      self.user_id = token.payload.sub
    else
      self:write({
        status = 403,
        json = {
          errors = { 'InvalidAuthorization' }
        }
      })
    end
  end
end)

function app:handle_404()
  return { status = 404, json = {
    errors = {
      'RouteNotFound'
    }
  }}
end

return app
