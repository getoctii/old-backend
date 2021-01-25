local config = require 'lapis.config'.get()
local http = require 'resty.http'
local json = require 'cjson'
local uuid = require 'util.uuid'
local map = require 'array'.map

return function(channels, event, payload)
  local event_id = assert(uuid())
  local httpc = assert(http.new())

  assert(httpc:request_uri(config.pushpin .. '/publish', {
    method = 'POST',
    headers = {
      ['content-type'] = 'application/json'
    },
    body = json.encode({
      items = map(channels, function(channel)
        return {
          channel = channel,
          id = event_id,
          formats = {
            ['http-stream'] = {
              content = string.format('id: %s\nevent: %s\ndata: %s\n\n', event_id, event, json.encode(payload))
            }
          }
        }
      end)
    })
  }))
end