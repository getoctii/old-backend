local config = require 'lapis.config'.get()
local http = require 'resty.http'
local json = require 'cjson'

return function(payload)
  -- TODO: Reenable
  return
  -- local httpc = assert(http.new())

  -- assert(httpc:request_uri(config.push .. '/push', {
  --   method = 'POST',
  --   headers = {
  --     ['content-type'] = 'application/json'
  --   },
  --   body = json.encode(payload)
  -- }))
end