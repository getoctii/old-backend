local config = require('lapis.config')

config('development', {
  postgres = {
    host = '127.0.0.1',
    user = 'postgres',
    password = 'password',
    database = 'neko-chat'
  },
  public_key = [[
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvRQOVUjdLhMRdUYdK24S
7pYfX5MYyd65pRdlcaMManR4m4AdtXHhSruWM0aTIag0k5IuK2BQW6+kdOD4arng
YCsH+eTJKh18z7u0muR0If8GXuTVyShKyEkChJHzTc6dLC2GxxkQS6SDWSK6D6eH
2Rgz7/r8rYDaVVmkcw7hZ2sWYxcGT2f3aWzbBcFcj07inxIeKtIWvS6S4Ci8L8ys
4Eanlhx6rxeFwCG6/Ywq5qb4ffHBYF0ucQMXyv91eRr12Yfczpz5rbXEn6Eh6Akk
Z9ai3DXGGUC8nXuFMifabUxIb0/fjh0PYU1zPuYM1TPFzfrWvgfkGKQcYw2btvR3
SwNmJjcd3v74kTkmekwjkzEgSb676HXhwT86gfS3EakfaHW5tDwvER1ZV3q9gqdx
XWz1GlqsBQRuw3w6zR+zc85b6AJRRc2mlU8Ki3msyxRDcE/StixKweVmN7oCgWw2
OvjSL9IruzDUgMdrWp60EiQynSvM9RCgrSeGxkmY5pBZ/GuRHHFWtqhAFu1Zg983
5ahN25uz6yqcz+3mzWdXlLpAHPBdfmWxQPhmkSpm0g7bzc8Qf3dgO5evpN4gxl/T
tCnmnFOmmuR4MB951dyi5zVXvYbRgXshG/7CD2ZufuIvV9T9Yw878peP/OoLrPj/
sVjHEqQHSFC3qMZAAqwjm7MCAwEAAQ==
-----END PUBLIC KEY-----
  ]],
  redis = {
    host = '127.0.0.1',
    port = 32769
  },
  tastyURL = 'http://127.0.0.1:5561'
})
