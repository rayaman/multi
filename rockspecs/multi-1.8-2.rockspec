package = "multi"
version = "1.8-2"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v1.8.2",
}
description = {
   summary = "Lua Multi tasking library",
   detailed = [[
      This library contains many methods for multi tasking. From simple side by code using multi objs, to using coroutine based Threads and System threads(When you have lua lanes installed or are using love2d. Optional)
   ]],
   homepage = "https://github.com/rayaman/multi",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.4"
}
build = {
   type = "builtin",
   modules = {
      -- Note the required Lua syntax when listing submodules as keys
      ["multi.init"] = "mulit/mulit/init.lua",
      ["multi.all"] = "mulit/mulit/all.lua",
      ["multi.compat.backwards[1,5,0]"] = "mulit/mulit/compat/backwards[1,5,0].lua",
      ["multi.compat"] = "mulit/mulit/compat/love2d.lua",
      ["multi.integration.lanesManager"] = "mulit/mulit/integration/lanesManager.lua",
      ["multi.integration.loveManager"] = "mulit/mulit/integration/loveManager.lua",
      ["multi.integration.shared.shared"] = "mulit/multi/integration/shared/shared.lua"
   }
}