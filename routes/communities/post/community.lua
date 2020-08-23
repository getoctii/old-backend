local Communities = require 'models.communities'
local Members = require 'models.members'
local validate = require 'lapis.validate'

local uuid = require 'util.uuid'

return function(self)
  validate.assert_valid(self.params, {
    { 'name', exists = true, min_length = 2, max_length = 16, { 400, 'CommunityNameInvalid' }}
  })

  local community = assert(Communities:create({ -- TODO: handle all db errors
    id = assert(uuid()),
    name = self.params.name, -- TODO: Differenciate between query params and form
    icon = 'https://file.coffee/u/B4XnANcwWKP.jpeg',
    large = true
  }))

  Members:create({
    id = assert(uuid()),
    user_id = self.user_id, -- TODO: check that acc exists
    community_id = community.id
  })

  return {
    json = {
      id = community.id,
      name = community.name,
      icon = community.icon,
      large = community.large
    }
  }
end