local config = require 'lapis.config'

local function read_file(filename)
  local file = io.open(filename)
  local data = file:read("*a")
  file:close()
  return data
end

config('development', {
  postgres = {
    host = 'postgres',
    user = 'neko',
    password = 'neko',
    database = 'neko',
  },
  jwt = {
    public = 'keys/public.pem',
    private = 'keys/private.pem',
    voice = 'keys/voice.pem'
  },
  code_cache = 'on',
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
  voice_token = 'keys/voice_token',
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  resolver = '127.0.0.11'
})

config('production', {
  postgres = {
    host = 'db.octii.chat',
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
      private_url = 'http://192.168.0.181:8081',
    }
  },
  voice_token = '/run/secrets/voice_token',
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  push = 'http://push:8080',
  resolver = '127.0.0.11',
  subscriptions_webhook = '/run/secrets/subscriptions_webhook'
})
