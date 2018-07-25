-- set up the package
package.path="?/init.lua;?.lua;"..package.path
-- Import the libraries
multi = require("multi")
local GLOBAL, THREAD = require("multi.integration.lanesManager").init()
nGLOBAL = require("multi.integration.networkManager").init()
-- Act as a master node
master = multi:newMaster{
	name = "Main", -- the name of the master
	--noBroadCast = true, -- if using the node manager, set this to true to avoid double connections
	--managerDetails = {"localhost",12345}, -- the details to connect to the node manager (ip,port)
}
master.OnError(function(name,err)
	print(name.." has encountered an error: "..err)
end)
master.OnNodeConnected(function(name)
	-- name is the name of the node that connected
end)
-- Starting the multitasker
settings = {
	priority = 0, -- 0, 1 or 2
	protect = false,
}
multi:threadloop(settings) -- both mainloop and threadloop can be used. one pirotizes threads where the other pirotizes multiobjs
--multi:mainloop(settings)
