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
      ["multi.init"] = "multi/init.lua",
      ["multi.all"] = "multi/all.lua",
      ["multi.compat.backwards[1,5,0]"] = "multi/compat/backwards[1,5,0].lua",
      ["multi.compat"] = "multi/compat/love2d.lua",
      ["multi.integration.lanesManager"] = "multi/integration/lanesManager.lua",
      ["multi.integration.loveManager"] = "multi/integration/loveManager.lua",
      ["multi.integration.shared.shared"] = "multi/integration/shared/shared.lua"
   }
}