package.path = package.path .. ';./?/init.lua'
local lapis = require 'lapis'
local validate = require 'lapis.validate'
local config = require 'lapis.config'.get()

local jwt = require 'resty.jwt'
local validators = require 'resty.jwt-validators'
local raven = require 'raven'
local UsersModel = require 'models.users'

local app = lapis.Application()
app.include = function(self, a)
	self.__class.include(self, a, nil, self)
end

-- Validators
require 'util.validators.uuid'
require 'util.validators.matches_regexp'
require 'util.validators.is_array'

function validate.validate_functions.exists(input)
  return not not input, '%s must be provided'
end

local rvn = raven.new {
  sender = require('raven.senders.ngx').new {
    dsn = 'https://15652eb7625a4485bbabde18e37fed37@o271654.ingest.sentry.io/5453638'
  }
}

-- Middleware
app:before_filter(function(self)
  self.res.headers['Access-Control-Allow-Origin'] = '*'
  self.res.headers['Access-Control-Allow-Methods'] = '*'
  self.res.headers['Access-Control-Allow-Headers'] = 'Authorization, Content-Type, Cache-Control'

  if self.req.method == 'OPTIONS' then
    self:write({
      status = 203
    })
    return
  end

  if self.route_name ~= 'users.login' and self.route_name ~= 'integrations.events' and self.route_name ~= 'integrations.commands' and self.route_name ~= 'integrations.reply' and self.route_name ~= 'users.register' and self.route_name ~= 'users.newsletter' and self.route_name ~= 'voice.users' and self.route_name ~= 'voice.started' and self.route_name ~= 'channels.webhook' then
    local token = jwt:verify(config.jwt.public, self.req.headers.Authorization or self.params.authorization, {
      iss = validators.equals('chat.innatical.com'),
      aud = validators.equals('chat.innatical.com'),
      nbf = validators.is_not_before(),
      exp = validators.is_not_expired()
    })

    if token.verified == true then
      local user = UsersModel:find({ id = token.payload.sub })
      if user then
        if not user.disabled then
          self.user = user
        else
          self:write({
            status = 403,
            json = {
              errors = { 'DisabledUser' }
            }
          })
        end
      else
        self:write({
          status = 404,
          json = {
            errors = { 'UserNotFound' }
          }
        })
      end
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

if config._name == 'production' then
  function app:handle_error(err, trace)
    print('ERROR:', err, trace)
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
elseif config._name == 'development' then
  function app:handle_error(err, trace)
    print('ERROR:', err, trace)
    return {
      status = 500,
      layout = false,
      err .. trace
    }
  end
end



function app:handle_404()
  return { status = 404, json = {
    errors = {
      'RouteNotFound'
    }
  }}
end

-- Routes
app:include('routes.users')
app:include('routes.channels')
app:include('routes.communities')
app:include('routes.events')
app:include('routes.invites')
app:include('routes.conversations')
app:include('routes.messages')
app:include('routes.voice')
app:include('routes.groups')
app:include('routes.admin')
app:include('routes.members')
app:include('routes.relationships')
app:include('routes.products')
app:include('routes.integrations')

return app
