package = "multi"
version = "1.11.0"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v1.11.0",
}
description = {
   summary = "Lua Multi tasking library",
   detailed = [[
      This library contains many methods for multi tasking. From simple side by side code using multi-objs, to using coroutine based Threads and System threads(When you have lua lanes installed or are using love2d)
   ]],
   homepage = "https://github.com/rayaman/multi",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "bin",
   "lanes"
}
build = {
   type = "builtin",
   modules = {
      ["multi.init"] = "multi/init.lua",
      ["multi.all"] = "multi/all.lua",
      ["multi.compat.backwards[1,5,0]"] = "multi/compat/backwards[1,5,0].lua",
      ["multi.compat.love2d"] = "multi/compat/love2d.lua",
      ["multi.integration.lanesManager"] = "multi/integration/lanesManager.lua",
      ["multi.integration.loveManager"] = "multi/integration/loveManager.lua",
      ["multi.integration.luvitManager"] = "multi/integration/luvitManager.lua",
      ["multi.integration.shared"] = "multi/integration/shared.lua"
   }
}