local Model = require('lapis.db.model').Model

local Roles = Model:extend('roles', {
  relations = {
    { 'community', belongs_to = 'communities' },
  }
})

Roles.permissions = enum {
  read_messages = 1,
  send_messages = 2,
  mention_members = 3,
  embed_links = 4,
  create_invites = 5,
  ban_members = 6,
  kick_members = 7,
  manage_permissions = 8,
  manage_channels = 9,
  manage_invites = 10,
  manage_server = 11,
  administrator = 12,
  owner = 13,
  mention_roles = 14,
  mention_everyone = 15,
  mention_someone = 16
}

return Roles
