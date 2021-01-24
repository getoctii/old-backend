local Model = require('lapis.db.model').Model

local Communities = Model:extend('communities', {
  relations = {
    { 'channels', has_many = 'channels' },
    { 'members', has_many = 'members' },
    { 'invites', has_many = 'invites' },
    { 'owner', belongs_to = 'users' },
    { 'system_channel', belongs_to = 'channels' }
  }
})

return Communities
