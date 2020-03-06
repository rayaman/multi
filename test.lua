package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
local GLOBAL,THREAD = require("multi.integration.lanesManager"):init()
func = THREAD:newFunction(function(test)
    print(test)
    THREAD.sleep(1)
    return "Hello World!"
end)
func("Did it work").connect(function(...)
    print(...)
    --os.exit()
end)
local serv = multi:newService(function(self,data)
    local name = thread.getRunningThread().Name
    print(name)
end)
serv.Start()
serv.SetPriority(multi.Priority_Low)
multi:lightloop()