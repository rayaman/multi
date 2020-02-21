package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
--local sterilizer = require("multi.integration.sterilization")
local multi,thread = require("multi"):init()

multi:lightloop()