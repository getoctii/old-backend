local db = require 'lapis.db'
local schema = require 'lapis.db.schema'
local new_uuid = require 'util.uuid'
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
    schema.create_table('groups', {
      { 'id',  uuid },
      { 'community_id', uuid },
      { 'name', types.text },
      { 'color', types.text { null = true } },
      { 'permissions', types.integer { array = true, default = '{}' } }
    })
  end,
  [1610681439] = function()
    schema.add_column('newsletter_subscribers', 'created_at', types.time { default = 'NOW()'} )
    schema.add_column('newsletter_subscribers', 'updated_at', types.time { default = 'NOW()'} )
  end,
  [1611178536] = function()
    schema.add_column('codes', 'created_at', types.time {default = 'NOW()'} )
    schema.add_column('codes', 'updated_at', types.time {default = 'NOW()'} )
  end,
  [1611282439] = function()
    schema.add_column('messages', 'type', types.integer { default = 1 } )
    schema.add_column('communities', 'system_channel_id', 'uuid')
  end,
  [1611287258] = function ()
    db.insert('users', {
      id = '30eeda0f-8969-4811-a118-7cefa01098a3',
      username = 'system',
      discriminator = 0,
      avatar = 'https://file.coffee/u/bat4HJ36LT.png',
      email = '',
      password = '',
      disabled = true
    })
  end,
  [1611550703] = function()
    schema.create_table('group_members', {
      { 'member_id', uuid },
      { 'group_id', uuid },

      'PRIMARY KEY (member_id, group_id)'
    })
  end,
  [1611632743] = function()
    schema.add_column('groups', 'order', types.integer { default = 1 })
  end,
  [1611775713] = function()
    schema.add_column('communities', 'base_permissions', types.integer { array = true, default = '{}' })
  end,
  [1612142220] = function()
    schema.add_column('channels', 'order', types.integer { default = 1 })
  end,
  [1612380833] = function()
    db.query('ALTER TABLE users ADD CONSTRAINT email_constraint UNIQUE (email)')
  end,
  [1612390290] = function()
    db.query('ALTER TABLE members ADD CONSTRAINT member_constraint UNIQUE (user_id, community_id)')
  end,
  [1612746591] = function()
    schema.drop_column('relationships', 'accepted')
    schema.drop_column('relationships', 'id')
    schema.add_column('relationships', 'type', types.integer)
    db.query('ALTER TABLE relationships ADD PRIMARY KEY (user_id, recipient_id)')
  end,
  [1613172821] = function()
    schema.add_column('channels', 'type', types.integer { default = 1 })
    schema.add_column('channels', 'parent_id', 'uuid')
  end,
  [1613703708] = function()
    db.query('ALTER TABLE invites ALTER COLUMN code TYPE text')
  end,
  [1613704965] = function()
    db.query('ALTER TABLE invites ADD CONSTRAINT code_constraint UNIQUE (code)')
  end,
  [1614068514] = function()
    schema.create_table('group_overrides', {
      { 'channel_id', uuid },
      { 'group_id', uuid },
      { 'allow', types.integer { array = true, default = '{}' } },
      { 'deny', types.integer { array = true, default = '{}' } },

      'PRIMARY KEY (channel_id, group_id)'
    })
  end,
  [1615183494] = function()
    schema.add_column('channels', 'base_allow', types.integer { array = true, default = '{}' })
    schema.add_column('channels', 'base_deny', types.integer { array = true, default = '{}' })
  end,
  [1616546624] = function()
    schema.add_column('users', 'developer', types.boolean { default = false })
  end,
  [1616618673] = function()
    schema.add_column('communities', 'organization', types.boolean { default = false })
  end,
  [1616645571] = function()
    schema.create_table('products', {
      { 'id', uuid },
      { 'name', types.text },
      { 'icon', types.text },
      { 'description', types.text },
      { 'organization_id', uuid }
    })
  end,
  [1616717031] = function()
    schema.create_table('resources', {
      { 'id', uuid },
      { 'name', types.text },
      { 'type', types.integer },
      { 'product_id', uuid }
    })
  end,
  [1616720855] = function()
    schema.add_column('resources', 'payload', 'json')
  end,
  [1616722872] = function()
    schema.create_table('versions', {
      { 'product_id', uuid },
      { 'number', types.integer },
      { 'payload', 'json NOT NULL'},

      'PRIMARY KEY (product_id, number)'
    })
  end,
  [1616723935] = function()
    schema.add_column('versions', 'name', types.text)
    schema.add_column('versions', 'description', types.text)
  end,
  [1616724761] = function()
    schema.add_column('versions', 'approved', types.boolean { default = false })
  end,
  [1616730151] = function()
    schema.create_table('purchases', {
      { 'user_id', uuid },
      { 'product_id', uuid },

      'PRIMARY KEY (user_id, product_id)'
    })
  end,
  [1616731642] = function()
    schema.add_column('products', 'approved', types.boolean { default = false })
  end,
  [1616814093] = function()
    schema.add_column('products', 'banner', types.text { null = true })
  end,
  [1616815731] = function()
    schema.add_column('products', 'tagline', types.text { default = '' })
  end,
  [1618937126] = function()
    schema.create_table('voice_rooms', {
      { 'id', uuid },
      { 'server', uuid },
      { 'channel_id', uuid }
    })
  end,
  [1620088180] = function()
    schema.add_column('users', 'keychain', 'json')
  end,
  [1619821237] = function()
    schema.add_column('voice_rooms', 'users', types.text { array = true, default = '{}' })
  end,
  [1620347684] = function()
    schema.add_column('messages', 'encrypted_content', 'json')
    schema.add_column('messages', 'self_encrypted_content', 'json')
    db.query('ALTER TABLE messages ALTER COLUMN content DROP NOT NULL')
  end,
  [1620930665] = function()
    db.query('ALTER TABLE codes ALTER COLUMN id TYPE text')
    schema.add_column('codes', 'partner', types.boolean { default = false })
  end,
  [1621206754] = function()
    schema.add_column('users', 'plus', types.boolean { default = false })
  end,
  [1621383890] = function()
    schema.add_column('conversations', 'voice_channel_id', types.text { null = true })

    for _, row in ipairs(db.query('SELECT * FROM conversations')) do
      local id = new_uuid()
      db.insert('channels', {
        id = id,
        name = 'nekos-are-cute',
        community_id = db.NULL,
        type =  3
      })
      db.query('UPDATE conversations SET voice_channel_id=? WHERE id=?', id, row.id)
    end
  end,
  [1621555678] = function()
    schema.add_column('users', 'totp_key', types.text { null = true })
  end,
  [1622077676] = function()
    schema.add_column('messages', 'rich_content', 'json')
    schema.add_column('channels', 'webhook_code', uuid .. ' DEFAULT gen_random_uuid()')
  end,
  [1623537216] = function()
    schema.create_table('integrations', {
     { 'community_id', uuid },
     { 'resource_id', uuid },
      'PRIMARY KEY (community_id, resource_id)'
    })
  end,
  [1623632088] = function()
    schema.add_column('resources', 'commands', 'json DEFAULT \'[]\'')
  end
}