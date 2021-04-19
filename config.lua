local config = require 'lapis.config'

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
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  resolver = '1.1.1.1'
})
