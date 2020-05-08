package.path="?.lua;?/init.lua;?.lua;?/?/init.lua;"..package.path
multi,thread = require("multi"):init()
GLOBAL,THREAD = require("multi.integration.pesudoManager"):init()

multi:newThread(function()
    while true do
        thread.sleep(1)
        print("hello!")
    end
end)
multi:newThread(function()
    while true do
        thread.sleep(1)
        print("hello!")
        --prrint("hehe")
    end
end)


multi:mainloop({print=true})