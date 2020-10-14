package.path = package.path .. ';./?/init.lua'
local lapis = require 'lapis'
local config = require 'lapis.config'.get()

local jwt = require 'resty.jwt'
local inspect = require 'inspect'
local validators = require 'resty.jwt-validators'
local helpers = require 'lapis.application'
local mm = require 'mm'
local raven = require 'raven'

local app = lapis.Application()

-- Validators
require 'util.validators.uuid'
require 'util.validators.matches_regexp'

-- Routes
require('routes.users')(app)
require('routes.channels')(app)
require('routes.communities')(app)
require('routes.events')(app)
require('routes.invites')(app)
require('routes.conversations')(app)
require('routes.messages')(app)
-- require('routes.voice')(app)

local rvn = raven.new {
  sender = require('raven.senders.ngx').new {
    dsn = 'https://15652eb7625a4485bbabde18e37fed37@o271654.ingest.sentry.io/5453638'
  }
}

-- Middleware
app:before_filter(function(self)
  self.res.headers['Access-Control-Allow-Origin'] = '*'
  self.res.headers['Access-Control-Allow-Methods'] = '*'
  self.res.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type'

  if self.req.method == 'OPTIONS' then
    self:write({
      status = 203
    })
    return
  end

  if self.route_name ~= 'users.post.login' and self.route_name ~= 'users.post.register' and self.route_name ~= 'users.post.newsletter' then
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

function app:handle_error(err, trace)
  rvn:captureException({{
    type = err,
    value = trace,
    module = '__builtins__'
  }}, {
    transaction = ngx.var.request_uri
  })
  return {
    status = 500,
    json = {
      errors = {
        'ServerError'
      }
    }
  }
end

function app:handle_404()
  return { status = 404, json = {
    errors = {
      'RouteNotFound'
    }
  }}
end

return app
