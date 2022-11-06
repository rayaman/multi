package = "multi"
version = "15.3-0"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v15.3.0",
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
      --["multi.integration.lovrManager"] = "integration/lovrManager/init.lua",
      --["multi.integration.lovrManager.extensions"] = "integration/lovrManager/extensions.lua",
      --["multi.integration.lovrManager.threads"] = "integration/lovrManager/threads.lua",
      ["multi.integration.pesudoManager"] = "integration/pesudoManager/init.lua",
      ["multi.integration.pesudoManager.extensions"] = "integration/pesudoManager/extensions.lua",
      ["multi.integration.pesudoManager.threads"] = "integration/pesudoManager/threads.lua",
      ["multi.integration.luvitManager"] = "integration/luvitManager.lua",
      ["multi.integration.threading"] = "integration/threading.lua",
      --["multi.integration.networkManager"] = "integration/networkManager.lua",
   }
}