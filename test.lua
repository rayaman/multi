package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.pesudoManager"):init()
test = true
local haha = true
local test = multi:newSystemThreadedTable("test"):init()
test['hi'] = "Hello World!!!"
test['bye'] = "Bye World!!!"
multi:newSystemThread("test_1",function()
    print(THREAD_NAME,THREAD_ID,THREAD.getName())
    print("thread",GLOBAL,THREAD,test,haha)
    tab = THREAD.waitFor("test"):init()
    print(tab["hi"])
end)
multi:newSystemThread("test_2",function()
    print(THREAD_NAME,THREAD_ID,THREAD.getName())
    print("thread",GLOBAL,THREAD,test,haha)
    tab = THREAD.waitFor("test"):init()
    print(tab["bye"])
end)

multi:mainloop()
