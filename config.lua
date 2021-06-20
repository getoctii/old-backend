local config = require 'lapis.config'

local function read_file(filename)
  local file = io.open(filename)
  if not file then return nil end
  local data = file:read("*a")
  file:close()
  return data
end

config('development', {
  postgres = {
    host = '127.0.0.1',
    user = 'postgres',
    password = 'password',
    database = 'neko-chat',
  },
  jwt = {
    public = 'secrets/auth_public',
    private = 'secrets/auth_private',
    voice = 'secrets/voice_private'
  },
  code_cache = 'off',
  default_profile_pictures = {
    'img1',
    'img2'
  },
  voice_servers = {
    ['56186404-d176-44e5-9176-b05b0f1e5c02'] = {
      public_url = 'ws://localhost:8080',
      private_url = 'http://host.docker.internal:8081'
    }
  },
  voice_token = 'secrets/voice_token',
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://127.0.0.1:5561',
  resolver = '1.1.1.1'
})

config('production', {
  postgres = {
    host = 'postgres',
    user = 'monolith',
    password = read_file('/run/secrets/db_password'),
    database = 'monolith',
  },
  jwt = {
    public = '/run/secrets/auth_public',
    private = '/run/secrets/auth_private',
    voice = '/run/secrets/voice_private'
  },
  code_cache = 'on',
  default_profile_pictures = {
    'https://cdn.octii.chat/assets/default.webp'
  },
  voice_servers = {
    ['8f50bcb4-996e-4182-8f78-abdc6cdf7756'] = {
      public_url = 'wss://voice.octii.chat',
      private_url = 'https://admin.voice.octii.chat',
    }
  },
  voice_token = '/run/secrets/voice_token',
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  push = 'http://push:8080',
  resolver = '127.0.0.11 ipv6=off',
  subscriptions_webhook = '/run/secrets/subscriptions_webhook'
})
