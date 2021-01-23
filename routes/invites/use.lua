local validate = require 'lapis.validate'
local helpers = require 'lapis.application'
local InvitesModel = require 'models.invites'
local MembersModel = require 'models.members'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local MessagesModel = require 'models.messages'
local ChannelsModel = require 'models.channels'

local joinMessages = {
  ' joined the community!',
  ' has arrived, back to work!',
  ' joined, did someone order a pizza?',
  ' has arrived, give me a break...',
  ' joined, I don\'t have any welcoming for you.'
}

local Use = {}

function Use:POST()
  validate.assert_valid(self.params, {
    { 'code', exists = true, is_uuid = true, 'InvalidCode' }
  })

  local invite = helpers.assert_error(InvitesModel:find({ code = self.params.code }), 'InviteNotFound')
  helpers.assert_error(not MembersModel:find({ community_id = invite.community_id, user_id = self.user.id }), { 400, 'AlreadyInCommunity' })

  local community = invite:get_community()

  local member = assert(MembersModel:create({
    id = uuid(),
    community_id = invite.community_id,
    user_id = self.user.id
  }))

  broadcast('user:' .. self.user.id, 'NEW_MEMBER', { -- Send in same event
    id = member.id,
    community = {
      id = community.id,
      icon = community.icon,
      name = community.name,
      large = community.large,
      owner_id = community.owner_id
    }
  })

  resubscribe('user:' .. self.user.id)

  broadcast('community:' .. community.id, 'JOIN_MEMBER', {
    id = member.id,
    community_id = community.id,
    user_id = self.user.id
  })

  if community.system_channel_id then
    local systemChannel = helpers.assert_error(ChannelsModel:find({ id = community.system_channel_id }), 'SystemChannelNotFound')
    local row = MessagesModel:create({
      id = uuid(),
      author_id = '30eeda0f-8969-4811-a118-7cefa01098a3',
      content = '<@' .. self.user.id .. '>' .. joinMessages[math.random(#joinMessages)],
      channel_id = community.system_channel_id,
      type = 3
    })

    local author = row:get_author()

    broadcast('channel:' .. community.system_channel_id, 'NEW_MESSAGE', {
      id = row.id,
      created_at = row.created_at,
      updated_at = row.updated_at,
      content = row.content,
      channel_id = row.channel_id,
      author = {
        id = author.id,
        username = author.username,
        avatar = author.avatar,
        discriminator = author.discriminator
      },
      type = row.type,
      community_id = community.id,
      community_name = community.name,
      channel_name = systemChannel.name
    })
  end


  return {
    status = 200,
    json = {
      community_id = invite.community_id
    }
  }
end

return Use