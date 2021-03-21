local helpers = require 'lapis.application'
local InvitesModel = require 'models.invites'
local MembersModel = require 'models.members'
local uuid = require 'util.uuid'
local broadcast = require 'util.broadcast'
local resubscribe = require 'util.resubscribe'
local MessagesModel = require 'models.messages'
local db = require 'lapis.db'
local joinMessages = require 'util.messages'.joinMessages
local validate = require 'util.validate'
local types = require 'tableshape'.types

local Use = {}

function Use:GET()
  local params = validate(self.params, types.shape {
    code = types.string
  })

  local invite = helpers.assert_error(InvitesModel:find({ code = params.code }), 'InviteNotFound')
  local community = invite:get_community()

  return {
    json = {
      author_id = invite.author_id,
      community = {
        id = community.id,
        name = community.name,
        icon = community.icon,
        large = community.large,
        owner_id = community.owner_id
      }
    }
  }
end


function Use:POST()
  local params = validate(self.params, types.shape {
    code = types.string
  })

  local invite = helpers.assert_error(InvitesModel:find({ code = params.code }), { 404, 'InviteNotFound' })
  helpers.assert_error(not MembersModel:find({ community_id = invite.community_id, user_id = self.user.id }), { 400, 'AlreadyInCommunity' })

  local community = helpers.assert_error(invite:get_community(), { 404, 'InviteNotFound' })

  local member = assert(MembersModel:create({
    id = uuid(),
    community_id = invite.community_id,
    user_id = self.user.id
  }))

  invite:update({
    uses = db.raw('uses + 1')
  })

  local systemChannel = community:get_system_channel()

  if systemChannel then
    local row = MessagesModel:create({
      id = uuid(),
      author_id = '30eeda0f-8969-4811-a118-7cefa01098a3',
      content = '<@' .. self.user.id .. '>' .. joinMessages[math.random(#joinMessages)],
      channel_id = systemChannel.id,
      type = 3
    })

    local author = row:get_author()

    broadcast('channel:' .. systemChannel.id, 'NEW_MESSAGE', {
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
  -- wtf, so the message should be there before the fetch of channels even happens? wtf
  resubscribe('user:' .. self.user.id)

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
  -- wait, IT DIOESN'T CLEAR CACHE LMAO LMAOOOOOOOOOO I FIGURED IT OUT SAME TIME U WERE SAYING IT LOL
  broadcast('community:' .. community.id, 'JOIN_MEMBER', {
    id = member.id,
    community_id = community.id,
    user_id = self.user.id
  }) -- did it reload yet?

  return {
    status = 200,
    json = {
      community_id = invite.community_id
    }
  }
end

return Use