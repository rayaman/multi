multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.threading"):init() -- Auto detects your enviroment and uses what's available

jq = multi:newSystemThreadedJobQueue(5) -- Job queue with 4 worker threads
func = jq:newFunction("test",function(a,b)
    THREAD.sleep(2)
    return a+b
end)

for i = 1,10 do
    func(i,i*3).connect(function(data)
        print(data)
    end)
end

local a = true
b = false

multi:newThread("Standard Thread 1",function()
    while true do
        thread.sleep(1)
        print("Testing 1 ...",a,b,test)
    end
end).OnError(function(self,msg)
    print(msg)
end)

-- All upvalues are stripped! no access to the global, multi and thread are exposed however
multi:newISOThread("ISO Thread 2",function()
    while true do
        thread.sleep(1)
        print("Testing 2 ...",a,b,test) -- a and b are nil, but test is true
    end
end,{test=true,print=print})

.OnError(function(self,msg)
    print(msg)
end)

multi:mainloop()