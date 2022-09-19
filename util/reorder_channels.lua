local Channels = require 'models.channels'

local function reorder_channels(order)
  for i, v in ipairs(order) do
    local channel = Channels:find({ id = v })
    channel:update({
      order = i
    })
  end
end

return reorder_channels