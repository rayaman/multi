package.path="../?.lua;../?/init.lua;../?.lua;../?/?/init.lua;"..package.path
--[[
    This file runs all tests.
    Format:
        Expected:
            ...
            ...
            ...
        Actual:
            ...
            ...
            ...
    
    Each test that is ran should have a 5 second pause after the test is complete
    The expected and actual should "match" (Might be impossible when playing with threads)
    This will be pushed directly to the master as tests start existing.
]]
local multi, thread = require("multi"):init()

local good = false
runTest = thread:newFunction(function()
    local objects = multi:newProcessor("Basic Object Tests")
    objects.Start()
    otest = require("tests/objectTests")(objects,thread)
    thread.hold(otest.OnEvent)
    print("Timers: Ok")
    print("Connections: Ok")
    print("Threads: Ok")
    print(objects:getTasksDetails())
    good = true
    print("\nTests done")
    os.exit()
end,true)
print(runTest())
multi:mainloop()