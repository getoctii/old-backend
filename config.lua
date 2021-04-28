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
  voice_servers = {
    ['56186404-d176-44e5-9176-b05b0f1e5c02'] = {
      public_url = 'ws://localhost:8080',
      private_url = 'http://host.docker.internal:8081'
    }
  },
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
      public_url = 'wss://voice.octii.chat',
      private_url = 'http://voice_server:8081',
    }
  },
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  push = 'http://push:8080',
  resolver = '127.0.0.11'
})
