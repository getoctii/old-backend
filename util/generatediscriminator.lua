local lapis = require('lapis')
local db = require('lapis.db')

-- WARNING: not tested, don't trust
function GenerateDiscriminator(username)
  local takendiscriminators = db.select('DISTINCT discriminator FROM users WHERE username=?', username)
  local gendiscriminator = db.select('floor(random() * 9999 + 1)::int')
end