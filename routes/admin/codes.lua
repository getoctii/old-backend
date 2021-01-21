local helpers = require 'lapis.application'
local CodesDB = require 'models.codes'
local uuid = require 'util.uuid'
local empty = require 'array'.is_empty
local json = require 'cjson'
local db = require 'lapis.db'
local validate = require 'lapis.validate'
local OrderedPaginator = require 'lapis.db.pagination'.OrderedPaginator

local Codes = {}

function Codes:GET()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })

   local pager = OrderedPaginator(CodesDB, 'created_at', {
    per_page = 25,
    order = 'desc'
  })

  local page = pager:get_page(self.params.created_at)

  if empty(page) then
    page = json.empty_array
  end
  
  return {
    json = page
  }
end

function Codes:POST()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })
  local code = assert(CodesDB:create({ id = uuid(), used = false }))
  return {
    json = {
      code = code
    }
  }
end

function Codes:DELETE()
  validate.assert_valid(self.params, {
    { 'id', exists = true, is_uuid = true, 'InvalidUUID' }
  })
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })
  
  local code = helpers.assert_error(CodesDB:find({ id = self.params.id }), 'CodeNotFound')

  assert(db.delete('codes', {
    id = code.id
  }))

  return {
    layout = false
  }
end

return Codes