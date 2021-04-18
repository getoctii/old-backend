local config = require 'lapis.config'

config('development', {
  postgres = {
    host = os.getenv('POSTGRES_IP'),
    port = tonumber(os.getenv('POSTGRES_PORT')),
    user = 'neko',
    password = os.getenv('POSTGRES_PASSWORD'),
    database = 'neko',
    port = 5432
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
  pushpin = 'http://' .. os.getenv('NOMAD_ADDR_pushpin_admin'),
  resolver = '1.1.1.1'
})
