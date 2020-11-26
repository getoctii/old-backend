local config = require 'lapis.config'

config('development', {
  postgres = {
    host = 'postgres',
    user = 'octii',
    password = 'octii',
    database = 'octii',
    port = 5432
  },
  jwt = {
    public = 'keys/public.pem',
    private = 'keys/private.pem'
  },
  code_cache = 'off',
  ssl_certificate = '/etc/ssl/cert.pem',
  port = 8086,
  pushpin = 'http://pushpin:5561',
  resolver = '127.0.0.11 ipv6=off'
})