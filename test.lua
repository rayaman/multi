package.path = "./?/init.lua;"..package.path
multi,thread = require("multi"):init()
--GLOBAL,THREAD = require("multi.integration.threading"):init() -- Auto detects your enviroment and uses what's available


test = thread:newFunction(function()
    return 1,2,nil,3,4,5,6,7,8,9
end,true)
print(test())
multi:newThread("testing",function()
    print("#Test = ",test())
    print(thread.hold(function()
        print("Hello!")
        return false
    end,{
        interval = 2,
        cycles = 3
    })) -- End result, 3 attempts within 6 seconds. If still false then timeout
    print("held")
end).OnError(function(...)
    print(...)
end)

-- local sandcount = 0
-- function multi:newProcessor(name)
--     local c = {}
--     setmetatable(c,{__index = self})
--     local multi,thread = require("multi"):init() -- We need to capture the t in thread
--     local name = name or "Processor_"..sandcount
--     sandcount = sandcount + 1
--     c.Mainloop = {}
--     c.Type = "process"
--     c.Active = false
--     c.OnError = multi:newConnection()
--     c.process = self:newThread(name,function()
--         while true do
--             thread.hold(function()
--                 return sandbox.Active
--             end)
--             c:uManager()
--         end
--     end).OnError(c.OnError)
--     function c.Start()
--         c.Active = true
--     end
--     function c.Stop()
--         c.Active = false
--     end
--     return c
-- end

-- sandbox = multi:newProcessor()
-- sandbox:newTLoop(function()
--     print("testing...")
-- end,1)

-- test2 = multi:newTLoop(function()
--     print("testing2...")
-- end,1)

-- sandbox:newThread("Test Thread",function()
--     while true do
--         thread.sleep(1)
--         print("Thread Test...")
--     end
-- end)

-- sandbox.Start()

multi:mainloop()