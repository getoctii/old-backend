local schema = require 'lapis.db.schema'
local types = schema.types

local uuid = 'uuid NOT NULL'

return {
  [1588207587] = function()
    schema.create_table('users', {
      { 'id', uuid },
      { 'username', types.text },
      { 'avatar', types.text },
      { 'password', types.text },
      { 'discriminator', types.integer },
      { 'email', types.text },

      'PRIMARY KEY (id)'
    })

    schema.create_table('messages', {
      { 'id', uuid },
      { 'author_id', uuid },
      { 'content', types.text },
      { 'channel_id', uuid },
      { 'created_at', types.time },
      { 'updated_at', types.time },

      'PRIMARY KEY (id)'
    })

    schema.create_table('communities', {
      { 'id', uuid },
      { 'icon', types.text },
      { 'name', types.text },
      { 'large', types.boolean },

      'PRIMARY KEY (id)'
    })

    schema.create_table('invites', {
      { 'id', uuid },
      { 'code', uuid },
      { 'community_id', uuid },
      { 'author_id', uuid },
      { 'created_at', types.time },
      { 'updated_at', types.time },
      { 'uses', types.integer },

      'PRIMARY KEY (id)'
    })

    schema.create_table('channels', {
      { 'id', uuid },
      { 'name', types.text },
      { 'community_id', 'uuid' },

      'PRIMARY KEY (id)'
    })

    schema.create_table('members', {
      { 'id', uuid },
      { 'user_id', uuid },
      { 'community_id', uuid },

      'PRIMARY KEY (id)'
    })
  end,
  [1597624597] = function()
    schema.create_table('conversations', {
      { 'id', uuid },
      { 'channel_id', uuid}
    })

    schema.create_table('participants', {
      { 'id', uuid },
      { 'conversation_id', uuid},
      { 'user_id', uuid }
    })
  end,
  [1598154490] = function()
    schema.create_table('codes', {
      { 'id', uuid },
      { 'used', types.boolean }
    })
  end,
  [1598571122] = function()
    schema.create_table('relationships', {
      { 'id', uuid },
      { 'user_id', uuid },
      { 'recipient_id', uuid },
      { 'accepted', types.boolean }
    })
  end,
  [1598764297] = function()
    schema.add_column('users', 'status', 'text')
  end,
  [1600578423] = function()
    schema.add_column('communities', 'owner_id', uuid)
  end,
  [1601356257] = function()
    schema.create_table('voice_sessions', {
      { 'id', uuid },
      { 'user_id', uuid },
      { 'recipient_id', uuid }
    })
  end,
  [1601514092] = function()
    schema.add_column('members', 'created_at', types.time {default = 'NOW()'})
    schema.add_column('members', 'updated_at', types.time {default = 'NOW()'})
  end,
  [1602648987] = function()
    schema.create_table('newsletter_subscribers', {
      { 'email', types.text },

      'PRIMARY KEY (email)'
    })
  end,
  [1604033064] = function()
    schema.add_column('users', 'state', types.integer { default = 1 })
  end,
  [1604034079] = function()
    schema.add_column('channels', 'description', 'text')
    schema.add_column('channels', 'color', types.text { default = '#0081FF' })
  end,
  [1604374460] = function()
    schema.drop_column('users', 'state')
    schema.add_column('users', 'state', types.integer { default = 4 })
    schema.add_column('users', 'last_ping', 'integer')
  end,
  [1604471448] = function()
    schema.add_column('users', 'badges', types.integer { array = true, default = '{}' })
  end,
  [1604996163] = function()
    schema.create_table('read', {
      { 'user_id', uuid },
      { 'channel_id', uuid },
      { 'last_read_id', uuid },

      'PRIMARY KEY (user_id, channel_id)'
    })
  end,
  [1606976331] = function()
    schema.create_table('mentions', {
      { 'id', uuid },
      { 'message_id', uuid },
      { 'user_id', uuid },

      'PRIMARY KEY (id)'
    })
  end,
  [1607906314] = function()
    schema.add_column('mentions', 'read', types.boolean)
  end,
  [1607918238] = function()
    schema.add_column('users', 'color', types.text { default = '#0081FF' })
  end,
  [1608605219] = function()
    schema.add_column('users', 'disabled', types.boolean { default = false })
  end,
  [1609557118] = function()
    schema.create_table('notification_tokens', {
      { 'user_id', uuid },
      { 'platform', types.text },
      { 'token', types.text },

      'PRIMARY KEY (user_id, platform, token)'
    })
  end,
  [1609806303] = function()
    schema.add_column('roles', {
      { 'id',  uuid },
      { 'community_id', uuid },
      { 'name', types.text },
      { 'color', types.text { null = true } },
      { 'permissions', types.integer { array = true, default = '{}' } }
    })
  end
}