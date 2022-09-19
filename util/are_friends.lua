local RelationshipsModel = require 'models.relationships'

return function(peer1_id, peer2_id)
  return not not (RelationshipsModel:find(
    { user_id = peer1_id, recipient_id = peer2_id, type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST }
  )
  and RelationshipsModel:find(
      { user_id = peer2_id, recipient_id = peer1_id, type = RelationshipsModel.types.OUTGOING_FRIEND_REQUEST }
    ))
end