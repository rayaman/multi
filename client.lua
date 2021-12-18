package.path = "?/init.lua;?.lua;"..package.path

local multi, thread = require("multi"):init()
net = require("lnet.tcp")

client = net.newTCPClient("localhost",12345)
multi:newThread(function()
    while true do
        thread.sleep(1)
        client:send(multi:getTasksDetails())
    end
end)

multi:newThread(function()
    while true do
        thread.sleep(.01)
        multi:newLoop()
    end
end)


multi:mainloop()