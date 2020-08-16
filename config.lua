local config = require('lapis.config')

config('development', {
  postgres = {
    host = '127.0.0.1',
    user = 'postgres',
    password = 'password',
    database = 'neko-chat',
    port = 5432
  },
  public_key = [[
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAycAYEaK2kQt4M0L1LHHv
KsnEHbOD+r0ntSmxFFzDEjgoIaUTI+ixLSnJysa2RGYE5Ia3Y6o0mGUZYnWh+0Tp
R0NrJOt/XZM5OnGhmyJSEtjzF7ieCxTi5qayBbB53Xf4KTMKLFgpzmaHW2Yh0rH8
91H7bkY4EOung9vn3SOJw/ZsplAbXDjOfrTl90tq/t6G5HRRB+lNtYjB2s7elAlN
R7H6BcAVS50dDvkT6wYACzJMjzo0Euku2M9UCqtkobLpaTNXB0hKIfcyLHeof9lc
hAHHYbcHgOd+TB4JtOWhJEFvkEFE4fQTlhy0KsnVInZG5yzYNzE2F/AbE+fHC2zn
UOQdiEhXpTamb1fY5VwEoAvqjIOw6yNoZS+elZNSHA2GtjhAA7pL7s5kNTTGW1WB
3qDyTQR/Dilzl8qWagXy7suQVnEzgTUlh+UE/oJb3BBs7wYKgtvfibLuTPS4STB8
VyU72tX02/SdELCVNnC6PvC/xU0JasmYM5tuP9AoIw+97yAAYVBtDS4aDK551Cpv
gyKdAwcDwwhNxu49QonzMU7B8kpRy4HUkqdTTzdeMkxeueoSBTZ1PNPKoWSVFjy1
cmUrfaE390TK5zM0qrAEq2guvGo3zEUAKKaFw991RKFyNj2E54Pb09e4O3nJc1jj
ZiVF7BK7RyZbVRkFrzx2Ob0CAwEAAQ==
-----END PUBLIC KEY-----
]],
  redis = {
    host = '127.0.0.1',
    port = 32769
  },
  port = 8086,
  tastyURL = 'http://127.0.0.1:5561'
})
