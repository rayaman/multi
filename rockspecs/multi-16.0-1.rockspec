package = "multi"
version = "16.0-1"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v16.0.1",
}
description = {
   summary = "Lua Multi tasking library",
   detailed = [[
      This library contains many methods for multi tasking. Features non coroutine based multi-tasking, coroutine based multi-tasking, and system threading (Requires use of an integration).
      Check github for documentation.
   ]],
   homepage = "https://github.com/rayaman/multi",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["multi"] = "init.lua",
      ["multi.integration.lanesManager"] = "integration/lanesManager/init.lua",
      ["multi.integration.lanesManager.extensions"] = "integration/lanesManager/extensions.lua",
      ["multi.integration.lanesManager.threads"] = "integration/lanesManager/threads.lua",
      ["multi.integration.loveManager"] = "integration/loveManager/init.lua",
      ["multi.integration.loveManager.extensions"] = "integration/loveManager/extensions.lua",
      ["multi.integration.loveManager.threads"] = "integration/loveManager/threads.lua",
      ["multi.integration.loveManager.utils"] = "integration/loveManager/threads.lua",
      --["multi.integration.lovrManager"] = "integration/lovrManager/init.lua",
      --["multi.integration.lovrManager.extensions"] = "integration/lovrManager/extensions.lua",
      --["multi.integration.lovrManager.threads"] = "integration/lovrManager/threads.lua",
      ["multi.integration.pseudoManager"] = "integration/pseudoManager/init.lua",
      ["multi.integration.pseudoManager.extensions"] = "integration/pseudoManager/extensions.lua",
      ["multi.integration.pseudoManager.threads"] = "integration/pseudoManager/threads.lua",
      ["multi.integration.luvitManager"] = "integration/luvitManager.lua",
      ["multi.integration.threading"] = "integration/threading.lua",
      ["multi.integration.sharedExtensions"] = "integration/sharedExtensions/init.lua",
      ["multi.integration.priorityManager"] = "integration/priorityManager/init.lua",
      --["multi.integration.networkManager"] = "integration/networkManager.lua",
   }
}