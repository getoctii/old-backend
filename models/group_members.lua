local Model = require('lapis.db.model').Model

local GroupMembers = Model:extend('group_members', {
  relations = {
    { 'member', belongs_to = 'member' },
    { 'group', belongs_to = 'groups' }
  },
  primary_key = { 'member_id', 'group_id' }
})

return GroupMembers
