local schema = require 'lapis.db.schema'
local types = schema.types

return {
  [1588207587] = function()
    schema.create_table('users', {
      { 'id', 'uuid NOT NULL' },
      { 'username', types.text },
      { 'avatar', types.text },
      { 'password', types.text },
      { 'discriminator', types.integer },
      { 'email', types.text },

      'PRIMARY KEY (id)'
    })

    schema.create_table('messages', {
      { 'id', 'uuid NOT NULL' },
      { 'author_id', 'uuid NOT NULL' },
      { 'content', types.text },
      { 'channel_id', 'uuid NOT NULL' },
      { 'created_at', types.time },
      { 'updated_at', types.time },

      'PRIMARY KEY (id)'
    })

    schema.create_table('communities', {
      { 'id', 'uuid NOT NULL' },
      { 'icon', types.text },
      { 'name', types.text },
      { 'large', types.boolean },

      'PRIMARY KEY (id)'
    })

    schema.create_table('invites', {
      { 'id', 'uuid NOT NULL' },
      { 'code', 'uuid NOT NULL' },
      { 'community_id', 'uuid NOT NULL' },
      { 'author_id', 'uuid NOT NULL' },
      { 'created_at', types.time },
      { 'updated_at', types.time },
      { 'uses', types.integer },

      'PRIMARY KEY (id)'
    })

    schema.create_table('channels', {
      { 'id', 'uuid NOT NULL' },
      { 'name', types.text },
      { 'community_id', 'uuid' },

      'PRIMARY KEY (id)'
    })

    schema.create_table('members', {
      { 'id', 'uuid NOT NULL' },
      { 'user_id', 'uuid NOT NULL' },
      { 'community_id', 'uuid NOT NULL' },

      'PRIMARY KEY (id)'
    })
  end,
  [1597624597] = function()
    schema.create_table('conversations', {
      { 'id', 'uuid NOT NULL' },
      { 'channel_id', 'uuid NOT NULL'}
    })

    schema.create_table('participants', {
      { 'id', 'uuid NOT NULL' },
      { 'conversation_id', 'uuid NOT NULL'},
      { 'user_id', 'uuid NOT NULL' }
    })
  end,
  [1598154490] = function()
    schema.create_table('codes', {
      { 'id', 'uuid NOT NULL' },
      { 'used', types.boolean }
    })
  end,
  [1598571122] = function()
    schema.create_table('relationships', {
      { 'id', 'uuid NOT NULL' },
      { 'user_id', 'uuid NOT NULL' },
      { 'recipient_id', 'uuid NOT NULL' },
      { 'accepted', types.boolean }
    })
  end,
  [1598764297] = function()
    schema.add_column('users', 'status', 'text')
  end,
  [1600578423] = function()
    schema.add_column('communities', 'owner_id', 'uuid NOT NULL')
  end,
  [1601356257] = function()
    schema.create_table('voice_sessions', {
      { 'id', 'uuid NOT NULL' },
      { 'user_id', 'uuid NOT NULL' },
      { 'recipient_id', 'uuid NOT NULL' }
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
      { 'user_id', 'uuid NOT NULL' },
      { 'channel_id', 'uuid NOT NULL' },
      { 'last_read_id', 'uuid NOT NULL' },

      'PRIMARY KEY (user_id, channel_id)'
    })
  end,
  [1606976331] = function()
    schema.create_table('mentions', {
      { 'id', 'uuid NOT NULL' },
      { 'message_id', 'uuid NOT NULL' },
      { 'user_id', 'uuid NOT NULL' },

      'PRIMARY KEY (id)'
    })
  end,
  [1607906314] = function()
    schema.add_column('mentions', 'read', types.boolean)
  end,
  [1607918238] = function()
    schema.add_column('users', 'color', types.text { default = '#0081FF' })
  end,
}