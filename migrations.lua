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
  end
}