package.path = "./?/init.lua;"..package.path
multi,thread = require("multi"):init()
--GLOBAL,THREAD = require("multi.integration.threading"):init() -- Auto detects your enviroment and uses what's available

test = thread:newFunction(function(a,b)
    thread.sleep(1)
    return a,b
end)
print(test(1,2).connect(function(...)
    print(...)
end))
test:Pause()
print(test(1,2).connect(function(...)
    print(...)
end))
test:Resume()
print(test(1,2).connect(function(...)
    print(...)
end))

-- test = thread:newFunction(function()
--     return 1,2,nil,3,4,5,6,7,8,9
-- end,true)
-- print(test())
-- multi:newThread("testing",function()
--     print("#Test = ",test())
--     print(thread.hold(function()
--         print("Hello!")
--         return false
--     end,{
--         interval = 2,
--         cycles = 3
--     })) -- End result, 3 attempts within 6 seconds. If still false then timeout
--     print("held")
-- end).OnError(function(...)
--     print(...)
-- end)

-- sandbox = multi:newProcessor()
-- for i,v in pairs(sandbox.process) do
--     print(i,v)
-- end
-- io.read()
-- sandbox:newTLoop(function()
--     print("testing...")
-- end,1)

-- test2 = multi:newTLoop(function()
--     print("testing2...")
-- end,1)

-- sandbox:newThread("Test Thread",function()
--     local a = 0
--     while true do
--         thread.sleep(1)
--         a = a + 1
--         print("Thread Test: ".. multi.getCurrentProcess().Name)
--         if a == 10 then
--             sandbox.Stop()
--         end
--     end
-- end).OnError(function(...)
--     print(...)
-- end)
-- multi:newThread("Test Thread",function()
--     while true do
--         thread.sleep(1)
--         print("Thread Test: ".. multi.getCurrentProcess().Name)
--     end
-- end).OnError(function(...)
--     print(...)
-- end)

-- sandbox.Start()

multi:mainloop()