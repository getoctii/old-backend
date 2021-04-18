local config = require 'lapis.config'

config('development', {
  postgres = {
    host = '127.0.0.1',
    user = 'neko',
    password = os.getenv('POSTGRES_PASSWORD'),
    database = 'neko',
  },
  jwt = {
    public = 'keys/public.pem',
    private = 'keys/private.pem'
  },
  code_cache = 'off',
  default_profile_pictures = {
    'img1',
    'img2'
  },
  ssl_certificate = '/etc/ssl/cert.pem',
  port = tonumber(os.getenv('NOMAD_PORT_gateway')),
  pushpin = 'http://' .. os.getenv('PUSHPIN_ADMIN'),
  resolver = '1.1.1.1'
})
