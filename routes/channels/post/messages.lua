local helpers = require 'lapis.application'
local json = require 'cjson'
local http = require 'lapis.nginx.http'
local config = require 'lapis.config'.get()

local Channels = require 'models.channels'
local Messages = require 'models.messages'
local uuid = require 'util.uuid'
local mm = require 'mm'
local http = require 'resty.http'

return function(self)
  local channel = helpers.assert_error(Channels:find({ id = self.params.id }), 'ChannelNotFound')

  local row = Messages:create({
    id = uuid(),
    author_id = self.user_id,
    content = self.params.content,
    channel_id = channel.id
  })

  local message = {
    id = row.id,
    created_at = row.created_at,
    updated_at = row.updated_at,
    content = row.content
  }

  local message_event = {
    id = row.id,
    created_at = row.created_at,
    updated_at = row.updated_at,
    content = row.content,
    channel_id = row.channel_id,
    author_id = row.author_id
  }

  -- local _, status_code = http.simple({
  --   url = config.tastyURL .. '/publish',
  --   method = 'POST',
  --   headers = {
  --     ['content-type'] = 'application/json'
  --   },
  --   body = json.encode({
  --     channel = 'channel:' .. channel.id,
  --     id = message.id,
  --     formats = {
  --       ['http-stream'] = {
  --         content = 'event: channelevent\ndata: ' .. json.encode(message) .. '\n\n'
  --       }
  --     }
  --   })
  -- })

  local httpc = assert(http.new())
  mm(httpc:request_uri(config.tastyURL .. '/publish', {
    method = 'POST',
    headers = {
      ['content-type'] = 'application/json'
    },
    body = json.encode({
      items = {{
        channel = 'channel:' .. channel.id,
        id = message.id,
        formats = {
          ['http-stream'] = {
            content = string.format('id: %s\nevent: %s\ndata: %s\n\n', message.id, 'channelupdate', json.encode(message_event))
          }
        }
      }}
    })
  }))

  return {
    json = message
  }
end

-- owo me daddy hall of fame

-- uwu me daddy _DO NOT DELETE, DO NOT LEAK, CLASSIFIED_
