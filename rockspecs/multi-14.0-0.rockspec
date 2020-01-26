package = "multi"
version = "14.0-0"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v14.0.0",
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
   "lanes",
}
build = {
   type = "builtin",
   modules = {
      ["multi"] = "multi/init.lua",
      ["multi.compat.love2d"] = "multi/compat/love2d.lua",
      ["multi.integration.lanesManager"] = "multi/integration/lanesManager/init.lua",
	  ["multi.integration.lanesManager.extensions"] = "multi/integration/lanesManager/extensions.lua",
	  ["multi.integration.lanesManager.threads"] = "multi/integration/lanesManager/threads.lua",
	  ["multi.integration.loveManager"] = "multi/integration/loveManager/init.lua",
	  ["multi.integration.loveManager.extensions"] = "multi/integration/loveManager/extensions.lua",
	  ["multi.integration.loveManager.threads"] = "multi/integration/loveManager/threads.lua",
      ["multi.integration.luvitManager"] = "multi/integration/luvitManager.lua",
      --["multi.integration.networkManager"] = "multi/integration/networkManager.lua",
      ["multi.integration.shared"] = "multi/integration/shared.lua"
   }
}