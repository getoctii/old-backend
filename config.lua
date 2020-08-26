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

config('production', {
  postgres = {
    host = '127.0.0.1',
    user = 'neko',
    database = 'neko',
    password = '!@RtL4xhApQ&wEU^#NynQeAd8*ZYUnnA@ppSTpx!25^YuPs5ngi2X$wVA*n*dhRHsW!WaYZDWt7RbftJ#WrLCSbvfVi^dmoQ6ds!mcZnNH6SFTqPkkjVJ8@oE9QN2hg@'
  },
  port = 8080,
  code_cache = 'on',
  tastyURL = 'http://127.0.0.1:5561',
  public_key = [[
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEArJa9OLn2mRnJ3+L33vR6
6RCj1iUzYCMp05o+pGq6BgQDcc0EA7lGUPl55FrCJdznBL3t029E62SMpaiRKo0k
df54k5t6vPGqwB1ds+MYojm9omQ6uixgw8UfFz7dsQhAxgCGT9GuNqpy43nZnHja
6dzI577GkrUN77grtaSkre8llurEvXF674E+RQGeQ+v7Gefm3qTyuvkg4Cb+Q06t
Aq884MPc49imInb/UAgUPHhdRAtXUKMV73ZkweoaoqRQJXaYgYAHubLZlUV21paW
Ou4NEIliYMCN8O9cNslwhDdTzYctDWx+kWQZC1WsHoz0Dcfxl89xAOiJ5M2viDvF
yrkmlZ96M8xOuTvodiIzu5w1lVG3V4rGMhp2x8apdro0Z+fky5MkgCqXTQPASOtv
esc1evHPkaLNtyjjPeTJCbbanlhjTxIaLQIv8mkoSfPdW6A7xS1Fmy/Ooup4Ybw/
cYTtoETuDB//3sxksIk/f2+6cqb2vADkbeUqiz8y5koVDSoXO/cVx5l1JgFytASY
XjMCZzmpVGm7vSkjUxhRpERGtEZXD5yyJHKj4diReazP6HvGx40ZcnmAywb4fpkS
AF9poMVVj2hj6Uga52kG/hnKUk4/an81zJHg6Xuqu4WQVqA+JombJyau6y1toFB+
NKiufM6Lgb29loRhqsz0ZgkCAwEAAQ==
-----END PUBLIC KEY-----
]],
  secret = 'e5w9g$zi^8$$*5F4oK&sUuVa&nDGv4kf2yRfaZu6Kg3aDN6$CZv!dGhjKAkhJ!H3KrKQQiDgrkBjd#dqubZ7JKy3NZvUjcm3K2j3xo*bN2k!%@6WuoVhJzjhdmX7Uqpq'
})
