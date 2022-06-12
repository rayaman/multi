package = "multi"
version = "15.2-1"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v15.2.1",
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
      ["multi"] = "multi/init.lua",
      ["multi.integration.lanesManager"] = "multi/integration/lanesManager/init.lua",
      ["multi.integration.lanesManager.extensions"] = "multi/integration/lanesManager/extensions.lua",
      ["multi.integration.lanesManager.threads"] = "multi/integration/lanesManager/threads.lua",
      ["multi.integration.loveManager"] = "multi/integration/loveManager/init.lua",
      ["multi.integration.loveManager.extensions"] = "multi/integration/loveManager/extensions.lua",
      ["multi.integration.loveManager.threads"] = "multi/integration/loveManager/threads.lua",
      --["multi.integration.lovrManager"] = "multi/integration/lovrManager/init.lua",
      --["multi.integration.lovrManager.extensions"] = "multi/integration/lovrManager/extensions.lua",
      --["multi.integration.lovrManager.threads"] = "multi/integration/lovrManager/threads.lua",
      ["multi.integration.pesudoManager"] = "multi/integration/pesudoManager/init.lua",
      ["multi.integration.pesudoManager.extensions"] = "multi/integration/pesudoManager/extensions.lua",
      ["multi.integration.pesudoManager.threads"] = "multi/integration/pesudoManager/threads.lua",
      ["multi.integration.luvitManager"] = "multi/integration/luvitManager.lua",
      ["multi.integration.threading"] = "multi/integration/threading.lua",
      --["multi.integration.networkManager"] = "multi/integration/networkManager.lua",
   }
}