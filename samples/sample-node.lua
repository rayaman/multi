package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
node = multi:newNode{
	allowRemoteRegistering = true, -- allows you to register functions from the master on the node, default is false
	name = nil, -- default value
	--noBroadCast = true, -- if using the node manager, set this to true to prevent the node from broadcasting
	--managerDetails = {"localhost",12345}, -- connects to the node manager if one exists
}
settings = {
	priority = 0, -- 1 or 2
	stopOnError = true, -- if an actor crashes this will prevent it from constantly crashing over and over. You can leave this false and use multi.OnError to handle crashes as well
	protect = true, -- always protect a node. Not really needed since all executed xode from a master is protected on execution to prevent issues.
}
multi:mainloop(settings)
