local Model = require('lapis.db.model').Model

local Communities = Model:extend('communities', {
  relations = {
    { 'groups', has_many = 'groups' },
    { 'channels', has_many = 'channels' },
    { 'members', has_many = 'members' },
    { 'invites', has_many = 'invites' },
    { 'owner', belongs_to = 'users' },
    { 'system_channel', belongs_to = 'channels' },
    { 'products', has_many = 'products', key = 'organization_id' }
  }
})

return Communities
