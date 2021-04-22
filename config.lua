local config = require 'lapis.config'

config('development', {
  postgres = {
    host = 'postgres',
    user = 'neko',
    password = 'neko',
    database = 'neko',
  },
  jwt = {
    public = 'keys/public.pem',
    private = 'keys/private.pem'
  },
  code_cache = 'on',
  default_profile_pictures = {
    'img1',
    'img2'
  },
  voice_servers = {},
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  resolver = '127.0.0.11'
})

config('production', {
  postgres = {
    host = 'postgres',
    user = 'neko',
    password = 'neko',
    database = 'neko',
  },
  jwt = {
    public = 'keys/public.pem',
    private = 'keys/private.pem'
  },
  code_cache = 'on',
  default_profile_pictures = {
    'img1',
    'img2'
  },
  voice_servers = {
    ['8f50bcb4-996e-4182-8f78-abdc6cdf7756'] = {
      public_url = 'https://voice.octii.chat',
      private_url = 'http://voice_server:8081',
    }
  },
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  resolver = '127.0.0.11'
})
