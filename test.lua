package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
local multi,thread = require("multi"):init()
local GLOBAL, THREAD = require("multi.integration.lanesManager"):init()
multi:newSystemThread("test",function(msg)
    print("In thread:", THREAD.getID(), "Msg:", msg)
    while true do
        -- Hold forever :D
    end
end,"Passing a message")
multi:newThread("localthread",function()
    print("In local thread :D")
    while true do
        thread.sleep(1)
        print("...")
    end
end)
multi:mainloop()