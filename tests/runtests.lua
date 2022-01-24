package.path="./?.lua;../?.lua;../?/init.lua;../?.lua;../?/?/init.lua;"..package.path
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
local multi, thread = require("multi"):init{priority=true}
local good = false
runTest = thread:newFunction(function()
    local objects = multi:newProcessor("Basic Object Tests")
    objects.Start()
    require("tests/objectTests")(objects,thread)
    objects.Stop()
    local conn_thread = multi:newProcessor("Connection/Thread Tests")
    conn_thread.Start()
    require("tests/connectionTest")(conn_thread,thread)
    conn_thread.Stop()
    print(multi:getTasksDetails())
    os.exit()
end)
runTest().OnError(function(...)
	print("Error:",...)
end)
multi:mainloop()