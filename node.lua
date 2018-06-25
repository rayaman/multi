package.path="?/init.lua;?.lua;"..package.path
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
master = multi:newNode{
	crossTalk = false, -- default value
	allowRemoteRegistering = true,
	name = nil, -- default value
	noBroadCast = true,
	managerDetails = {"localhost",12345}, -- connects to the node manager if one exists
}
function RemoteTest(a,b,c)
	print("Yes I work!",a,b,c)
end
settings = {
	priority = 0, -- 1 or 2
	protect = false,
}
multi:mainloop(settings)
