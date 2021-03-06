local helpers = require 'lapis.application'
local CodesModel = require 'models.codes'
local uuid = require 'util.uuid'
local empty = require 'array'.is_empty
local json = require 'cjson'
local db = require 'lapis.db'
local validate = require 'util.validate'
local types = require 'tableshape'.types
local custom_types = require 'util.types'

local Codes = {}

function Codes:GET()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })

  --  local pager = OrderedPaginator(CodesModel, 'created_at', {
  --   per_page = 25,
  --   order = 'desc'
  -- })

  -- local page = pager:get_page(self.params.created_at)

  local page = self.params.last_code_id and
    db.query('SELECT * FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM "codes" order by created_at desc) t WHERE rank > (SELECT rank FROM (SELECT *, ROW_NUMBER() OVER (order by created_at desc) rank FROM codes) t2 WHERE id = ?) LIMIT 25', self.params.last_code_id)
    or CodesModel:select('ORDER BY created_at DESC LIMIT 25')

  if empty(page) then
    page = json.empty_array
  end

  return {
    json = page
  }
end

function Codes:POST()
  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })
  local code = assert(CodesModel:create({ id = uuid(), used = false }))
  return {
    json = {
      code = code
    }
  }
end

function Codes:DELETE()
  local params = validate(self.params, types.shape {
    id = custom_types.uuid
  })

  helpers.assert_error(self.user.discriminator == 0, { 403, 'NotAllowed' })

  local code = helpers.assert_error(CodesModel:find({ id = params.id }), 'CodeNotFound')

  assert(db.delete('codes', {
    id = code.id
  }))

  return {
    layout = false
  }
end

return Codes