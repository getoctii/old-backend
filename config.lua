local config = require 'lapis.config'

config('development', {
  postgres = {
    host = '127.0.0.1',
    user = 'postgres',
    password = 'password',
    database = 'neko-chat',
  },
  jwt = {
    public = os.getenv('AUTH_PUBLIC'),
    private = os.getenv('AUTH_PRIVATE'),
    voice = os.getenv('AUTH_VOICE')
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
  voice_token = os.getenv('VOICE_TOKEN'),
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://127.0.0.1:5561',
  resolver = '1.1.1.1'
})

config('production', {
  postgres = {
    host = 'db.innatical.com',
    user = 'octii',
    password = os.getenv('DB_PASSWORD'),
    database = 'octii',
  },
  jwt = {
    public = os.getenv('AUTH_PUBLIC'),
    private = os.getenv('AUTH_PRIVATE'),
    voice = os.getenv('AUTH_VOICE_PRIVATE')
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
  voice_token = os.getenv('VOICE_TOKEN'),
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = os.getenv('PUSHPIN_ADDR'),
  push = 'http://push:8080',
  resolver = '1.1.1.1',
  subscriptions_webhook = os.getenv('SUBSCRIPTIONS_WEBHOOK')
})
