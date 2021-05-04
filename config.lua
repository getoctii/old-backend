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