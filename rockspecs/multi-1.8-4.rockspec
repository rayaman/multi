package = "multi"
version = "1.8-4"
source = {
   url = "git://github.com/rayaman/multi.git",
   tag = "v1.8.4",
}
description = {
   summary = "Lua Multi tasking library",
   detailed = [[
      This library contains many methods for multi tasking. From simple side by side code using multiobjs, to using coroutine based Threads and System threads(When you have lua lanes installed or are using love2d. Optional) The core of the library works on lua 5.1+ however the systemthreading features are limited to 5.1
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
      ["multi.integration.shared.shared"] = "multi/integration/shared/shared.lua"
   }
}