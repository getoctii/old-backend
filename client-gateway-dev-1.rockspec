package = "client-gateway"
version = "dev-1"
source = {
   url = "git+ssh://git@git.innatical.com/project-neko/client-gateway.git"
}
description = {
   homepage = "https://git.innatical.com/project-neko/client-gateway.git",
   license = "proprietary"
}
build = {
   type = "builtin",
   modules = {
      app = "app.lua",
      ["applications.communities"] = "applications/communities.lua",
      ["applications.users"] = "applications/users.lua",
      config = "config.lua",
      migrations = "migrations.lua",
      ["models.channels"] = "models/channels.lua",
      ["models.communities"] = "models/communities.lua",
      ["models.members"] = "models/members.lua",
      ["models.messages"] = "models/messages.lua",
      ["models.users"] = "models/users.lua",
      reservednames = "reservednames.lua",
      ["util.jwt"] = "util/jwt.lua",
      ["util.uuid"] = "util/uuid.lua"
   }
}

dependencies = {
   "lua = 5.1",
   "lapis",
   "lua-resty-jwt",
   "luaossl",
   "argon2-ffi"
}