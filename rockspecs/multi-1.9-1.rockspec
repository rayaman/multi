package = "multi"
version = "1.9-1"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v1.9.1",
}
description = {
   summary = "Lua Multi tasking library",
   detailed = [[
      This library contains many methods for multi tasking. From simple side by side code using multiobjs, to using coroutine based Threads and System threads(When you have lua lanes installed or are using love2d. Optional) The core of the library works on lua 5.1+ however the systemthreading features are limited to 5.1 due to love2d and lua lanes and now luvit (See ReadMe on gotchas) being lua 5.1 only!
   ]],
   homepage = "https://github.com/rayaman/multi",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1, < 5.2"
}
build = {
   type = "builtin",
   modules = {
      -- Note the required Lua syntax when listing submodules as keys
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