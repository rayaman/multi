package.path = "?/init.lua;?.lua;"..package.path

local multi, thread = require("multi"):init()
net = require("lnet.tcp")

server = net.newTCPServer(12345)
server.OnDataRecieved(function(self,data)
    print(data)
end)

multi:mainloop()