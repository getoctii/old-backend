local helpers = require 'lapis.application'
local Codes = require 'models.codes'

local uuid = require 'util.uuid'
local contains = require 'array'.includes

local Code = {}

function Code:POST()
  helpers.assert_error(contains({ '99343aac-2301-415d-aece-17b021d3a459', '4e317329-8b17-4473-b1e1-4ceb9056cb5b', '987d59ba-1979-4cc4-8818-7fe2f3d4b560' }, self.user_id), { 403, 'NotAllowed' })
  local code = assert(Codes:create({ id = uuid(), used = false }))
  return {
    json = {
      code = code
    }
  }
end

return Code