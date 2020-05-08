package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.pesudoManager"):init()
test = true
local haha = true
jq = multi:newSystemThreadedJobQueue(100) -- Job queue with 4 worker threads
func = jq:newFunction("test",function(a,b)
    THREAD.sleep(2)
    return a+b
end)

for i = 1,100 do
    func(i,i*3).connect(function(data)
        print(data)
    end)
end

multi:mainloop()
