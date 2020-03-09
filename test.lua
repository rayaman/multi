package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi = require("multi")
GLOBAL, THREAD = require("multi.integration.lanesManager"):init()
local stt = multi:newSystemThreadedTable("stt")
stt["hello"] = "world"
multi:newSystemThread("test thread",function()
    local stt = GLOBAL["stt"]:init()
    print(stt["hello"])
end)
multi:lightloop()