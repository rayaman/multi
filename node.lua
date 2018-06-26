package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
master = multi:newNode{
	crossTalk = false, -- default value, allows nodes to talk to eachother. WIP NOT READY YET!
	allowRemoteRegistering = true, -- allows you to register functions from the master on the node, default is false
	name = nil, -- default value
	noBroadCast = true, -- if using the node manager, set this to true to prevent the node from broadcasting
	managerDetails = {"localhost",12345}, -- connects to the node manager if one exists
}
function RemoteTest(a,b,c) -- a function that we will be executing remotely
	print("Yes I work!",a,b,c)
end
settings = {
	priority = 0, -- 1 or 2
	protect = false, -- if something goes wrong we will crash hard, but the speed gain is good
}
multi:mainloop(settings)
