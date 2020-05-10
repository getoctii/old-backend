local lapis = require 'lapis'
local validate = require 'lapis.validate'
local encoding = require 'lapis.util.encoding'
local helpers = require 'lapis.application'
local Users = require 'models.users'
local jwt = require 'resty.jwt'

local rand = require 'openssl.rand'
local argon2 = require 'argon2'
local uuid = require 'util.uuid'

local app = lapis.Application()
require('applications.users')(app)

app:get('/', function()
  return 'Welcome to uHHHHHHH' .. require('lapis.version')
end)

return app
