local config = require 'lapis.config'

config('development', {
  postgres = {
    host = os.getenv('NOMAD_UPSTREAM_ADDR_postgres'),
    port = tonumber(os.getenv('NOMAD_UPSTREAM_PORT_postgres')),
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
  resolver = '127.0.0.11 ipv6=off'
})
