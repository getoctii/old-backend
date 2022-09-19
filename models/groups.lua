local model = require('lapis.db.model')
local Model, enum = model.Model, model.enum

local Groups = Model:extend('groups', {
  relations = {
    { 'community', belongs_to = 'communities' }
  }
})

Groups.permissions = enum {
  READ_MESSAGES = 1,
  SEND_MESSAGES = 2,
  EMBED_LINKS = 3,
  MENTION_MEMBERS = 4,
  MENTION_GROUPS = 5,
  MENTION_EVERYONE = 6,
  MENTION_SOMEONE = 7,
  CREATE_INVITES = 8,
  BAN_MEMBERS = 9,
  KICK_MEMBERS = 10,
  MANAGE_GROUPS = 11,
  MANAGE_CHANNELS = 12,
  MANAGE_INVITES = 13,
  MANAGE_COMMUNITY = 14,
  MANAGE_MESSAGES = 15,
  ADMINISTRATOR = 16,
  OWNER = 17,
  MANAGE_PRODUCTS = 18
}

return Groups
